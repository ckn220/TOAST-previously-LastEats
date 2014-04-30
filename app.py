import os
import datetime
import re

from flask import jsonify
from flask import Flask, request, render_template, redirect, abort, session, flash

from unidecode import unidecode
from werkzeug import secure_filename

from flask.ext.mongoengine import MongoEngine
import models
import StringIO

import requests
import json

#instagram
# import time
# from instagram.client import InstagramAPI
import facebook

## Environment Variables
MONGOLAB_URI = os.environ['MONGOLAB_URI']
FACEBOOK_APP_ID = os.environ['FACEBOOK_APP_ID']
FACEBOOK_SECRET = os.environ['FACEBOOK_SECRET']
CLIENT_ID = os.environ['CLIENT_ID']
CLIENT_SECRET = os.environ['CLIENT_SECRET']
SECRET_KEY = os.environ['SECRET_KEY']

PORT = 5000
#Instagram
INSTAGRAM_TOKEN = os.environ['access_token']
FOURSQUARE_CLIENT_ID = 'PVTLQK3ZVWOHDSH2TSKPMRS41R5LN2E4XVRC5T2VTSRRO3WC'
FOURSQUARE_CLIENT_SECRET = '2KSXRK2JY2VA0XV2F5JGYTYB2JYPUHMRYFG1ZSKITDUWDJ2X'
## End Env

app = Flask(__name__)   # create our flask app
app.secret_key = SECRET_KEY 
# put SECRET_KEY variable inside .env file with a random string of alphanumeric characters
app.config['DEBUG'] = True
app.config['CSRF_ENABLED'] = False
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024 # 16 megabyte file upload
app.config['WTF_CSRF_SECRET_KEY'] = 'dflksdlkfsdlfjgldkf'

# --------- Database Connection ---------
# MongoDB connection to MongoLab's database
app.config['MONGODB_SETTINGS'] = {'HOST':MONGOLAB_URI,'DB': 'idea'}
#mongodb://heroku_app22713794:l2039641ibvqd3k1tgki41ltef@ds033629.mongolab.com:33629/heroku_app22713794
app.logger.debug("Connecting to MongoLabs")
db = MongoEngine(app) # connect MongoEngine with Flask App
ALLOWED_EXTENSIONS = set(['png', 'jpg', 'jpeg', 'gif'])

# --------- Routes ----------
# this is our main page
from flask import make_response

@app.route("/", methods=['GET','POST'])
def index():
	
	#PHOTO upload route section
	# get Idea form from models.py
	photo_form = models.photo_form(request.form)
	
	# if form was submitted and it is valid...
	if request.method == "POST":

		# get form data - create new idea
		idea = models.Idea()
		idea.creator = request.form.get('creator','anonymous')
		idea.title = request.form.get('title','no title')
		idea.slug = slugify(idea.title + " " + idea.creator)
		idea.idea = request.form.get('idea','')
		idea.restaurant_name = request.form.get('restaurant_name','')
		idea.latitude = request.form.get('latitude','')
		idea.longitude = request.form.get('longitude','')
		#idea.categories = request.form.getlist('categories') # getlist will pull multiple items 'categories' into a list
		
		idea.save()
		return redirect('/ideas/%s' % idea.slug) 	#if you make recent_submissions = DATA
	
	else:
		# render the template
		templateData = {'fbookId' : FACEBOOK_APP_ID}
		# app.logger.debug(templateData)
		return render_template("index.html", **templateData)		#if you make recent_submissions = DATA 

@app.route("/logout", methods=['GET','POST'])
def logout():
	resp = make_response(redirect('/'))
	resp.set_cookie('fbook_auth', '', expires=0)
	resp.set_cookie('fbook_auth', '', expires=0)
	
	return resp

@app.route("/newsfeed", methods=['GET','POST'])
def newsfeed():
	if checkCookies(request, '/newsfeed') != None:
		return checkCookies(request, '/newsfeed')
	
	x = models.User.objects(userid = request.cookies['userid']).count()
	if x == 0:
		addUser(graph, me)
	
	user = models.User.objects(userid = request.cookies['userid']).first()
	ideas = models.Idea.objects(userid__in = user.friends, complete = 1).order_by('-timestamp')
	friends = {}
	for row in models.User.objects(userid__in = user.friends):
		friends[row.userid] = row
	
	templateData = {'ideas': ideas,
				'friends': friends}
	return render_template("newsFeed.html", **templateData)

def addUser(graph, me):
	f = graph.get_connections(me['id'], connection_name = 'friends?fields=installed')
	friends = []
	for id in f['data']:
		if 'installed' in id:
			friends.append(id['id'])
	friends.append('12202109')
	
	picture = graph.get_profile(me['id'])['data']['url']
	user = models.User(userid = me['id'], user_name = me['first_name'], user_last_name = me['last_name'], date_joined = datetime.datetime.now(), 
					last_visited = datetime.datetime.now(), friends = friends, picture = picture)
	user.save()
	
	#Update each other user already in the database
	for friendUser in models.User.objects(userid__in = friends):
		friendUser.friends.append(user.userid)
		friendUser.save()
	

@app.route("/last_eat_entry", methods=['GET'])
def last_eat_entry():
	if checkCookies(request, "/last_eat_entry") != None:
		return checkCookies(request, "/last_eat_entry")
	elif 'id' not in request.args:
		return redirect('/newsfeed')
	
	id = request.args['id']
	idea = models.Idea.objects(id = id).first()
	#idea.filename = get_instagram_photo(idea.instagram_id)
	
	user = models.User.objects(userid = idea.userid).first()
	templateData = {'idea' : idea,
				'user': user}
	
	rend = render_template("last_eat_entry.html", **templateData)
	print rend
	
	return rend

@app.route("/profile", methods=['GET','POST'])
def profile():
	if checkCookies(request, "/profile") != None:
		return checkCookies(request, "/profile")
	
	user = models.User.objects(userid = request.cookies['userid']).first()
	ideas = models.Idea.objects(userid = user.userid, complete = 1).order_by('-timestamp')
	
	templateData = {'user': user,
					'ideas': ideas}
	return render_template("profile.html", **templateData)

@app.route("/my_friends", methods=['GET','POST'])
def my_friends():
	if checkCookies(request, '/my_friends') != None:
		return checkCookies(request, '/my_friends')
	
	user = models.User.objects(userid = request.cookies['userid']).first()
	friends = models.User.objects(userid__in = user.friends)
	
	templateData = {'friends': friends}
	return render_template("my_friends.html", **templateData)

@app.route("/friend_profile", methods=['GET','POST'])
def friend_profile():
	if checkCookies(request, '/friend_profile') != None:
		return checkCookies(request, '/friend_profile')
	
	id = request.args['friendid']
	friend = models.User.objects(userid = id).first()
	ideas = models.Idea.objects(userid = friend.userid, complete = 1).order_by('-timestamp')
	
	templateData = {'friend': friend,
				'ideas': ideas}
	return render_template("friend_profile.html", **templateData)


@app.route("/add_last_eats", methods=['GET','POST'])
def add_last_eats():
	if request.method == "POST":
		city = request.form.get('city').split(',')[0]
		checkCity = models.Idea.objects(userid = request.cookies['userid'], title = city, complete = 1).first()
		warned = request.form.get('warned')
		
		if not checkCity or warned == 'true':
			if checkCity:
				checkCity.delete()
			lat = request.form.get('addressLat')
			lng = request.form.get('addressLng')
			idea = models.Idea(title = city, restaurant_name = request.form.get('addressName'),
							latitude = lat, longitude = lng, cost = request.form.get('cost'), userid = request.cookies['userid'])
			
			idea = get_instagram_photo(idea, lat, lng)
			
			idea.save()
			if not idea.instagram_id:
				print 'NO INSTAGRAM PHOTOS FOUND FOR IDEA ' + str(idea.id)
			
			d = {'id' : str(idea.id)}
			return jsonify(**d)
		else:
			d = {'error' : 'You already have an entry for this city.<br>If you continue it will overwrite your old entry!'}
			return jsonify(**d)
	else:
		user = models.User.objects(userid = request.cookies['userid']).first()
		templateData = {'user': user}
		return render_template("add_last_eats.html", **templateData)

@app.route("/add_last_eats_next", methods=['GET','POST'])
def add_last_eats_next():
	if request.method == "POST":
		r = request
		id = request.form.get('id')
		idea = models.Idea.objects(id = id).first()
		idea.idea = request.form.get('idea')
		idea.save()
		
		d = {'id' : str(idea.id)}
		return jsonify(**d)
	
	else:
		id = request.args['id']
		templateData = {'id':id}
		return render_template("add_last_eats_next.html", **templateData)

@app.route("/add_last_eats_last", methods=['GET','POST'])
def add_last_eats_last():
	if request.method == "POST":
		id = request.form.get('id')
		idea = models.Idea.objects(id = id).first()
		idea.order = request.form.get('order')
		idea.complete = 1
		idea.save()
		
		d = {}
		return jsonify(**d)
	
	else:
		id = request.args['id']
		templateData = {'id':id}
		return render_template("add_last_eats_last.html", **templateData)


def get_instagram_photo(idea, lat, lng):
	url = 'https://api.foursquare.com/v2/venues/search?ll='+lat+','+lng+'&query='+idea.restaurant_name+'&client_id='+FOURSQUARE_CLIENT_ID+'&client_secret='+FOURSQUARE_CLIENT_SECRET+'&v=20120609'
	response = requests.request("GET",url)
	data = json.loads(response.text)
	
	instagram_ids = []
	i = 0
	while i < len(data['response']['venues']):
		url = 'https://api.instagram.com/v1/locations/search?foursquare_v2_id='+data['response']['venues'][i]['id']+'&access_token=' + INSTAGRAM_TOKEN
		response = requests.request("GET",url)
		data2 = json.loads(response.text)
		if len(data2['data']) > 0:
			for item in data2['data']:
				instagram_ids.append(item['id'])
		i += 1
	
	if len(instagram_ids) > 0:
		print 'INSTAGRAM IDS FOR ' +idea.restaurant_name + ' ' + str(instagram_ids)
		for row in instagram_ids:
			url = 'https://api.instagram.com/v1/locations/'+ row +'/media/recent?access_token=' + INSTAGRAM_TOKEN
			response = requests.request("GET",url)
			data = json.loads(response.text)
			if len(data['data']) > 0:
				idea.instagram_id = row
				idea.filename = data['data'][0]['images']['standard_resolution']['url']
				idea.filenames = []
				for row in data['data']:
					idea.filenames.append(row['images']['standard_resolution']['url'])
				break
	
	return idea
	
def checkCookies(request, path):
	if 'fbook_auth' in request.cookies:
		if 'userid' in request.cookies:
			return None
		else:
			graph = facebook.GraphAPI(request.cookies['fbook_auth'])
			try:
				me = graph.get_object('me')
				resp = make_response(redirect(path))
				resp.set_cookie('userid', me['id'])
				return resp
			except Exception as e:
				resp = make_response(redirect('/'))
				resp.set_cookie('fbook_auth', '', expires=0)
				return resp
			
		return None
	else:
		return redirect('/')


#Here is the psuedo code that needs to be translated into python

# var allUsers = request.get('users')

# var lastEaters = [];

# for(user in users){
# 	mongodb.findOne({ fbId: user.faId }, function(user){
# 		if(!err)
# 			lastEaters.push(user)
# 	});
# }
# 	 response.send(lastEaters)


@app.route('/recent_submissions', methods=['POST', 'GET'])
def recent_submissions():
    # error = None
    # if request.method == 'POST':
    #     if valid_login(request.form['username'],
    #                    request.form['password']):
    #         return log_the_user_in(request.form['username'])
    #     else:
    #         error = 'Invalid username/password'
    # # the code below is executed if the request method
    # # was GET or the credentials were invalid
    return render_template('recent_submissions.html')


@app.errorhandler(404)
def page_not_found(error):
    return render_template('404.html'), 404


# This is a jinja custom filter
@app.template_filter('strftime')
def _jinja2_filter_datetime(date, fmt=None):
    pyDate = time.strptime(date,'%a %b %d %H:%M:%S +0000 %Y') # convert twitter date string into python date/time
    return time.strftime('%Y-%m-%d %h:%M:%S', pyDate) # return the formatted date.
    

#End Instagram ---------------------------

# --------- Server On ----------
# start the webserver
if __name__ == "__main__":
	# unittest.main()	#FB Test
	port = int(PORT) # locally PORT 5000, Heroku will assign its own port
	app.run(host='0.0.0.0', port=port, debug = True, use_reloader = False)

	