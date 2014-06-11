import os
import datetime
import time
import re
import math

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
import mongoScripts

## Environment Variables
MONGOLAB_URI = os.environ['MONGOLAB_URI']
FACEBOOK_APP_ID = os.environ['FACEBOOK_APP_ID']
FACEBOOK_SECRET = os.environ['FACEBOOK_SECRET']
CLIENT_ID = os.environ['CLIENT_ID']
CLIENT_SECRET = os.environ['CLIENT_SECRET']
SECRET_KEY = os.environ['SECRET_KEY']

PORT = int(os.environ.get("PORT", 5000))
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

@app.route("/", methods=['GET'])
def index():
	# render the template
	
	if 'userid' in request.cookies:
		resp = make_response(redirect('/newsfeed'))
		return resp
	
	if request.base_url == 'http://lasteats-dev.herokuapp.com/' or request.base_url == 'http://localhost:5000/':
		if 'userid' in request.args:
			resp = make_response(redirect('/newsfeed'))
			resp.set_cookie('userid', request.args['userid'])
			return resp
		else:
			users = models.User.objects()
			templateData = {'users': users,
						'fbookId' : FACEBOOK_APP_ID}
			return render_template("index.html", **templateData)
		
	templateData = {'fbookId' : FACEBOOK_APP_ID}
	return render_template("index.html", **templateData)		#if you make recent_submissions = DATA 

@app.route("/logout", methods=['GET','POST'])
def logout():
	templateData = {}
	return render_template("logout.html", **templateData)

@app.route("/newsfeed", methods=['GET','POST'])
def newsfeed():
	cookie_check = checkCookies(request, '/newsfeed')
	if cookie_check != None:
		return cookie_check
	
	if request.method == "POST":
		return get_newsfeed(request, 'newsfeed')
	else:
		x = models.User.objects(userid = request.cookies['userid']).count()
		if x == 0:
			addUser(request)
			
		user = models.User.objects(userid = request.cookies['userid']).first()
		
		if (datetime.datetime.now() - user.last_visited).days > 7:
			user = update_user(user)
			
		templateData = {'user': user}
		return render_template("newsfeed.html", **templateData)

def update_user(user):
	graph = facebook.GraphAPI()
	user.picture = graph.get_profile(user.userid)['data']['url']
	user.last_visited = datetime.datetime.now()
	user.save()
	
	return user

@app.route("/browse", methods=['GET','POST'])
def browse():
	
	if request.method == "POST":
		return get_newsfeed(request, 'browse')
	else:
		templateData = {}
		return render_template("browse.html", **templateData)

def get_newsfeed(request, path):
	lat = float(request.form.get('lat'))
	lng = float(request.form.get('lng'))
	if 'type' in request.form:
		type = request.form.get('type')
	else:
		type = None
	
	if path == 'newsfeed' and type != 'all':
		user = models.User.objects(userid = request.cookies['userid']).first()
		
		if type == 'saved':
			ideas = models.Idea.objects(id__in = user.saves, complete = 1)
		elif lat != None:
			ideas = models.Idea.objects(userid__in = user.friends, point__near=[lng, lat], complete = 1)[:20]
		else:
			ideas = models.Idea.objects(userid__in = user.friends, complete = 1).order_by('-timestamp')[:20]
			
		friends = {}
		for row in models.User.objects(userid__in = user.friends):
			friends[row.userid] = row
	else:
		if lat != None:
			ideas = models.Idea.objects(point__near=[lng, lat], complete = 1)[:20]
		else:
			ideas = models.Idea.objects(complete = 1).order_by('-timestamp')[:20]
		
		friendList = []
		for row in ideas:
			friendList.append(row.userid)
		friends = {}
		for row in models.User.objects(userid__in = friendList):
			friends[row.userid] = row
	
	idea_list = []
	for row in ideas:
		idea_list.append(row)
	
	templateData = {'ideas': idea_list[:20],
				'friends': friends}
	return render_template("newsfeed_content.html", **templateData)
	
def addUser(request):
	graph = facebook.GraphAPI(request.cookies['fbook_auth_old'])
	me = graph.get_object('me')
	f = graph.get_connections(me['id'], connection_name = 'friends?fields=installed,name,picture')
	friends = []
	all_friends = []
	for id in f['data']:
		all_friends.append({'id': id['id'], 'name': id['name'], 'picture': id['picture']['data']['url']})
		if 'installed' in id:
			friends.append(id['id'])
	
	picture = graph.get_profile(me['id'])['data']['url']
	user = models.User(userid = me['id'], user_name = me['first_name'], user_last_name = me['last_name'], date_joined = datetime.datetime.now(), 
					last_visited = datetime.datetime.now(), friends = friends, picture = picture)
	user.save()
	
	userFriends = models.UserFriends(userid = me['id'], all_friends = all_friends)
	userFriends.save()
	
	#Update each other user already in the database
	for friendUser in models.User.objects(userid__in = friends):
		friendUser.friends.append(user.userid)
		friendUser.save()
	
@app.route("/last_eat_entry", methods=['GET','POST','DELETE'])
def last_eat_entry():
		
	if request.method == "POST":
		cookie_check = checkCookies(request, "/last_eat_entry")
		if cookie_check != None:
			return cookie_check
		
		user = models.User.objects(userid = request.cookies['userid']).first()
		id = request.form.get('id')
		comment = request.form.get('comment')
		c = models.Comment(userid = user.userid, ideaid = id, comment_string = comment)
		c.save()
		
		templateData = {'comment': c, 'user': user}
		return render_template("comment.html", **templateData)
	
	elif request.method == "DELETE":
		id = request.form.get('id')
		idea = models.Comment.objects(id = id)
		idea.delete()
		return ''
		
	else:
		if 'id' not in request.args:
			if 'userid' in request.cookies:
				return redirect('/newsfeed')
			else:
				return redirect('/browse')
			
		id = request.args['id']
		idea = models.Idea.objects(id = id, complete = 1).first()
		#idea = get_instagram_photo(idea)
		idea.save()
		
		comments = models.Comment.objects(ideaid = str(idea.id))
		friends = {}
		for row in comments:
			f = models.User.objects(userid = row.userid).first()
			friends[f.userid] = f
		
		if 'userid' in request.cookies:
			current_user = request.cookies['userid']
		else:
			current_user = None
		
		friend = models.User.objects(userid = idea.userid).first()
		user = models.User.objects(userid = request.cookies['userid']).first()
		
		templateData = {'current_user': current_user,
					'idea' : idea,
					'idea_id' : str(idea.id),
					'user': user,
					'friend': friend,
					'friends': friends,
					'comments': comments}
		
		return render_template("last_eat_entry.html", **templateData)

@app.route("/love_idea", methods=['POST','DELETE'])
def love_idea():
	if request.method == "POST":
		id = request.form.get('id')
		userid = request.form.get('userid')
		
		idea = models.Idea.objects(id = id).first()
		if userid not in idea.likes:
			idea.likes.append(userid)
			idea.like_count = len(idea.likes)
			idea.save()
		
		return '200'
		
@app.route("/save_idea", methods=['POST','DELETE'])
def save_idea():
	if request.method == "POST":
		id = request.form.get('id')
		userid = request.form.get('userid')
		
		user = models.User.objects(userid = userid).first()
		if id not in user.saves:
			user.saves.append(id)
			user.save()
		
		return '200'

@app.route("/profile", methods=['GET','DELETE'])
def profile():
	cookie_check = checkCookies(request, "/profile")
	if cookie_check != None:
		return cookie_check

	if request.method == "DELETE":
		id = request.form.get('id')
		idea = models.Idea.objects(id = id)
		idea.delete()
		
		return ''
		
	else:
		user = models.User.objects(userid = request.cookies['userid']).first()
		ideas = models.Idea.objects(userid = user.userid, complete = 1).order_by('-timestamp')
		
		templateData = {'user': user,
						'ideas': ideas}
		return render_template("profile.html", **templateData)

@app.route("/my_friends", methods=['GET','POST'])
def my_friends():
	cookie_check = checkCookies(request, '/my_friends')
	if cookie_check != None:
		return cookie_check
	
	user = models.User.objects(userid = request.cookies['userid']).first()
	f = models.User.objects(userid__in = user.friends)
	friends = []
	for row in f:
		friends.append(row)
	friends = sorted(friends, key=lambda x: x.user_name)
	
	templateData = {'friends': friends}

@app.route("/friend_profile", methods=['GET','POST'])
def friend_profile():
	#cookie_check = checkCookies(request, '/friend_profile')
	#if cookie_check != None:
	#	return cookie_check
	
	if request.method == "POST":
		id = request.form.get('friendid')
		friend = models.User.objects(userid = id).first()
		lat = float(request.form.get('lat'))
		lng = float(request.form.get('lng'))
	
		ideas = models.Idea.objects(userid = friend.userid, point__near=[lng, lat], complete = 1)[:20]
		
		templateData = {'ideas': ideas[:20]}
		return render_template("profile_content.html", **templateData)

	else:
		id = request.args['friendid']
		friend = models.User.objects(userid = id).first()
		templateData = {'friend': friend}
		
		return render_template("friend_profile.html", **templateData)


@app.route("/city_filter", methods=['GET'])
def city_filter():
	cities = {}
	ordered_cities = []
	display_city = {}
	user = None
	if 'userid' in request.cookies:
		user = models.User.objects(userid = request.cookies['userid']).first()
		ideas = models.Idea.objects(userid__in = user.friends, complete = 1).order_by('-timestamp')
	else:
		ideas = models.Idea.objects(complete = 1).order_by('-timestamp')

	for idea in ideas:
		if idea.title not in cities:
			cities[idea.title] = []
			display_city[idea.title] = idea.title
			ordered_cities.append(idea.title)
		cities[idea.title].append(idea)	
	ordered_cities.sort()
	templateData = {'user': user,
				'filter': cities,
				'list': ordered_cities,
				'display': display_city}
	return render_template("filter.html", **templateData)

@app.route("/city", methods=['GET'])
def city():
	city = request.args['name']
	user = None
	if 'userid' in request.cookies:
		user = models.User.objects(userid = request.cookies['userid']).first()
		ideas = models.Idea.objects(userid__in = user.friends, title = city, complete = 1).order_by('-timestamp')
	else:
		ideas = models.Idea.objects(title = city, complete = 1).order_by('-timestamp')
	
	templateData = {'user': user,
				'city': city,
				'ideas': ideas}
	return render_template("city.html", **templateData)
	

@app.route("/price_filter", methods=['GET'])
def price_filter():
	prices = {1:[],2:[],3:[],4:[]}
	ordered_prices = [1,2,3,4]
	display_prices = {1:'$',2:'$$',3:'$$$',4:'$$$$'}
	user = models.User.objects(userid = request.cookies['userid']).first()
	ideas = models.Idea.objects(userid__in = user.friends, complete = 1).order_by('-timestamp')
	friends = {}
	for row in models.User.objects(userid__in = user.friends):
		friends[row.userid] = row

	for idea in ideas:
		prices[idea.cost].append(idea)
		
	templateData = {'user': user,
				'friends': friends,
				'filter': prices,
				'list': ordered_prices,
				'display': display_prices}
	return render_template("filter.html", **templateData)


@app.route("/notify_content", methods=['POST'])
def notify_content():
	userid = request.form.get('userid')
	
	ideas = models.Idea.objects(userid = userid).only('id')
	ids = []
	for idea in ideas:
		ids.append(str(idea.id))
	c = models.Comment.objects(ideaid__in = ids, seen = 0).order_by('timestamp')
	friend_ids = []
	idea_ids = []
	comments = []
	for row in c:
		friend_ids.append(row.userid)
		idea_ids.append(row.ideaid)
		comments.append(row)
		
	friends = {}
	for row in models.User.objects(userid__in = friend_ids):
		friends[row.userid] = row
	ideas = {}
	for row in models.Idea.objects(id__in = idea_ids):
		ideas[str(row.id)] = row
		
	templateData = {'friends': friends,
				'ideas': ideas,
				'comments': comments}
	return render_template("notify_content.html", **templateData)


@app.route("/requests", methods=['GET', 'POST'])
def requests():
	cookie_check = checkCookies(request, '/requests')
	if cookie_check != None:
		return cookie_check
	
	if request.method == "POST":
		city = request.form.get('city')
		title = city.split(',')[0]
		friends = request.form.getlist('friends[]')
		
		r = models.Request(title = title, full_city = city, userid = request.cookies['userid'], friends = friends)
		r.save()
		
		return 'Success'
		
	else:
		user = models.User.objects(userid = request.cookies['userid']).first()
		friends = models.User.objects(userid__in = user.friends)
	
		templateData = {'user': user,
				'friends': friends}
		return render_template("request.html", **templateData)

@app.route("/answered", methods=['GET', 'POST'])
def answered():
	cookie_check = checkCookies(request, '/answered')
	if cookie_check != None:
		return cookie_check
	
	requests = models.Request.objects(userid = request.cookies['userid'])
	ids = []
	friend_ids = []
	r = []
	for row in requests:
		r.append(row)
		friend_ids.extend(row.friends)
		ids.append(str(row.id))
		
	ideas = {}
	
	for row in models.Idea.objects(request_id__in = ids):
		if row.request_id not in ideas:
			ideas[row.request_id] = []
		ideas[row.request_id].append(row)
		friend_ids.append(str(row.userid))
	
	friends = {}
	for row in models.User.objects(userid__in = friend_ids):
		friends[row.userid] = row
	
	templateData = {'requests': r,
			'friends': friends,
			'ideas': ideas}
	return render_template("answered.html", **templateData)
	
	
@app.route("/add_last_eats", methods=['GET','POST'])
def add_last_eats():
	cookie_check = checkCookies(request, '/add_last_eats')
	if cookie_check != None:
		return cookie_check
	
	if request.method == "POST":
		full_city = request.form.get('city')
		city = full_city.split(',')[0]
		checkCity = models.Idea.objects(userid = request.cookies['userid'], title = city, complete = 1).first()
		warned = request.form.get('warned')
		
		if not checkCity or warned == 'true':
			if checkCity:
				checkCity.delete()
			lat = float(request.form.get('addressLat'))
			lng = float(request.form.get('addressLng'))
			idea = models.Idea(title = city, full_city = full_city, restaurant_name = request.form.get('addressName'),
							point = [lng, lat], userid = request.cookies['userid'])
			#cost = request.form.get('cost'), 
			
			idea = get_instagram_id(idea, lat, lng)
			
			idea.save()
			if not idea.instagram_id:
				print 'NO INSTAGRAM PHOTOS FOUND FOR IDEA ' + str(idea.id)
			
			d = {'id' : str(idea.id)}
			return jsonify(**d)
		else:
			d = {'error' : 'You already have <b>'+checkCity.restaurant_name+'</b> as your Last Eats in <b>'+checkCity.title+'</b>.<br>If you continue it will overwrite your old entry.'}
			return jsonify(**d)
	else:
		user = models.User.objects(userid = request.cookies['userid']).first()
		templateData = {'user': user}
		return render_template("add_last_eats.html", **templateData)

@app.route("/add_last_eats_next", methods=['GET','POST'])
def add_last_eats_next():
	cookie_check = checkCookies(request, '/add_last_eats_next')
	if cookie_check != None:
		return cookie_check
	
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

@app.route("/add_last_eats_next_next", methods=['GET','POST'])
def add_last_eats_next_next():
	cookie_check = checkCookies(request, '/add_last_eats_next_next')
	if cookie_check != None:
		return cookie_check
	
	if request.method == "POST":
		id = request.form.get('id')
		idea = models.Idea.objects(id = id).first()
		idea.order = request.form.get('order')
		idea.save()
		
		d = {'id' : str(idea.id)}
		return jsonify(**d)
	
	else:
		id = request.args['id']
		templateData = {'id':id}
		return render_template("add_last_eats_next_next.html", **templateData)
	
@app.route("/add_last_eats_last", methods=['GET','POST'])
def add_last_eats_last():
	cookie_check = checkCookies(request, '/add_last_eats_last')
	if cookie_check != None:
		return cookie_check
	
	if request.method == "POST":
		id = request.form.get('id')
		idea = models.Idea.objects(id = id).first()
		idea.filename = request.form.get('image')
		idea.complete = 1
		idea.save()
		
		d = {}
		return jsonify(**d)
	
	else:
		id = request.args['id']
		idea = models.Idea.objects(id = id).first()
		templateData = {'id':id,
						'idea': idea}
		return render_template("add_last_eats_last.html", **templateData)


def get_instagram_id(idea, lat, lng):
	url = 'https://api.foursquare.com/v2/venues/search?ll='+str(lat)+','+str(lng)+'&query='+idea.restaurant_name+'&client_id='+FOURSQUARE_CLIENT_ID+'&client_secret='+FOURSQUARE_CLIENT_SECRET+'&v=20120609'
	response = requests.request("GET",url)
	data = json.loads(response.text)
	
	instagram_ids = []
	i = 0
	while i < len(data['response']['venues']):
		url = 'https://api.instagram.com/v1/locations/search?foursquare_v2_id='+data['response']['venues'][i]['id']+'&access_token=' + INSTAGRAM_TOKEN
		try:
			response = requests.request("GET",url)
			text = response.text
			data2 = json.loads(text)
		except Exception as e:
			print e
			print 'ERROR IN INSTAGRAM LOADING'
			time.sleep(1)
			try:
				url = 'https://api.instagram.com/v1/locations/search?foursquare_v2_id='+data['response']['venues'][i]['id']+'&access_token=' + INSTAGRAM_TOKEN
				response = requests.request("GET",url)
				text = response.text
				data2 = json.loads(text)
			except:
				print 'DOUBLE ERROR!!!'
				data2 = {'data':[]}
				
		if len(data2['data']) > 0:
			for item in data2['data']:
				instagram_ids.append(item['id'])
		i += 1
	
	if len(instagram_ids) > 0:
		print 'INSTAGRAM IDS FOR ' +idea.restaurant_name + ' ' + str(instagram_ids)
		for row in instagram_ids:
			idea.filenames = []
			idea.instagram_id = row
			idea = get_instagram_photo(idea)
			if len(idea.filenames) > 0:
				break
			
	return idea
	
def get_instagram_photo(idea):
	url = 'https://api.instagram.com/v1/locations/'+ idea.instagram_id +'/media/recent?access_token=' + INSTAGRAM_TOKEN
	response = requests.request("GET",url)
	data = json.loads(response.text)
	if len(data['data']) > 0:
		idea.filename = data['data'][0]['images']['standard_resolution']['url']
		idea.filenames = []
		for row in data['data']:
			idea.filenames.append(row['images']['standard_resolution']['url'])
		
	return idea

def checkCookies(request, path):
	if 'fbook_auth' in request.cookies and 'userid' not in request.cookies:
		graph = facebook.GraphAPI(request.cookies['fbook_auth'])
		try:
			print 'NEW USER'
			me = graph.get_object('me')
			resp = make_response(redirect(path))
			resp.set_cookie('fbook_auth_old', request.cookies['fbook_auth'])
			resp.set_cookie('fbook_auth', '', expires=0)
			resp.set_cookie('userid', me['id'])
			return resp
		except Exception as e:
			resp = make_response(redirect('/'))
			resp.set_cookie('fbook_auth', '', expires=0)
			return resp
	
	if 'userid' in request.cookies and (models.User.objects(userid = request.cookies['userid']).count() > 0 or path == '/newsfeed'):
		return None
	
	elif 'fbook_auth_old' in request.cookies:
		graph = facebook.GraphAPI(request.cookies['fbook_auth_old'])
		try:
			me = graph.get_object('me')
			resp = make_response(redirect(path))
			resp.set_cookie('userid', me['id'])
			return resp
		
		except Exception as e:
			print e
			resp = make_response(redirect('/'))
			resp.set_cookie('fbook_auth', '', expires=0)
			return resp
		
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
	
	

	