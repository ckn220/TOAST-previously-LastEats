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
		# get existing images
		images = models.Idea.objects.order_by('-timestamp')
		
		# render the template
		templateData = {'fbookId' : FACEBOOK_APP_ID}
		# app.logger.debug(templateData)
		return render_template("index.html", **templateData)		#if you make recent_submissions = DATA 


@app.route("/newsfeed", methods=['GET','POST'])
def newsfeed():
	if checkCookies(request, '/newsfeed') != None:
		return checkCookies(request, '/newsfeed')
	
	x = models.User.objects(userid = request.cookies['userid']).count()
	if x == 0:
		addUser(graph, me)
	
	user = models.User.objects(userid = request.cookies['userid']).first()
	ideas = models.Idea.objects(userid__in = user.friends).order_by('-timestamp')
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
	

@app.route("/last_eat_entry", methods=['GET','POST'])
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
	return render_template("last_eat_entry.html", **templateData)

@app.route("/profile", methods=['GET','POST'])
def profile():
	if checkCookies(request, "/profile") != None:
		return checkCookies(request, "/profile")
	
	user = models.User.objects(userid = request.cookies['userid']).first()
	ideas = models.Idea.objects(userid = user.userid).order_by('-timestamp')
	
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
	ideas = models.Idea.objects(userid = friend.userid).order_by('-timestamp')
	
	templateData = {'friend': friend,
				'ideas': ideas}
	return render_template("friend_profile.html", **templateData)


@app.route("/add_last_eats", methods=['GET','POST'])
def add_last_eats():
	if request.method == "POST":
		city = request.form.get('city').split(',')[0]
		lat = request.form.get('addressLat')
		lng = request.form.get('addressLng')
		idea = models.Idea(title = city, restaurant_name = request.form.get('addressName'),
						latitude = lat, longitude = lng, cost = request.form.get('cost'), userid = request.cookies['userid'])
		
		url = 'https://api.instagram.com/v1/locations/search?lat='+lat+'&lng='+lng+'&distance=100&access_token=' + INSTAGRAM_TOKEN
		response = requests.request("GET",url)
		data = json.loads(response.text)
		instagram_ids = []
		i = 0
		while i < len(data['data']):
			found = False
			if idea.restaurant_name in data['data'][i]['name']:
				instagram_ids.append(data['data'][i]['id'])
			elif str(data['data'][i]['latitude']) == str(lat) or str(data['data'][i]['longitude']) == str(lng):
				instagram_ids.append(data['data'][i]['id'])
			i += 1
		
		if len(instagram_ids) > 0:
			for row in instagram_ids:
				url = 'https://api.instagram.com/v1/locations/'+ row +'/media/recent?access_token=' + INSTAGRAM_TOKEN
				response = requests.request("GET",url)
				data = json.loads(response.text)
				if len(data['data']) > 0:
					idea.instagram_id = row
					idea.filename = data['data'][0]['images']['standard_resolution']['url']
					break
		
		idea.save()
		if not idea.instagram_id:
			print 'NO INSTAGRAM PHOTOS FOUND FOR IDEA ' + str(idea.id)
		
		d = {'id' : str(idea.id)}
		return jsonify(**d)
	else:
		templateData = {}
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


def get_instagram_photo(id):
	url = 'https://api.instagram.com/v1/locations/'+id+'/media/recent?access_token=' + INSTAGRAM_TOKEN
	response = requests.request("GET",url)
	data = json.loads(response)
	
	return data
	
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
	
#login page

@app.route('/login', methods=['POST', 'GET'])
def login():

	if request.method == "POST":


		user = models.User()
		user.userid = request.form.get('userid','')
		user.user_name = request.form.get('user_name','')
		user.user_last_name = request.form.get('user_last_name','')
		# user.date_joined = request.form.get('date_joined','')
		# user.last_visited = request.form.get('last_visited','')
		user.friends = request.form.get('friends','')

		user.save()	#save it

    	return render_template('login.html')

# @app.route('/get_user', methods=['GET'])
# def get_user():
	
# 	make sure this works first
# 	userId = request.get('userId');

# 	models.User.findOne()

# 	IS THIS FRIIEND THAT WE FOUND ON FACEBOOK A USER?
# 	IF UNIQUE ID = UNIQUE ID, SAVE TO DB
# 	THE ENDPOINT SHOULD TAKE THE WHOLE LIST OF USERS 
# 	RETURN IDS THAT ARE 

# 	posts.find_one({"author": "Mike"})


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


@app.route('/display_fb_friends', methods=['POST','GET'])
def display_fb_friends():

	# user_form = models.user_form(request.form)

	# if form was submitted and it is valid...
	if request.method == "POST":

		user = models.User()
		user.userid = request.form.get('userid','')
		user.user_name = request.form.get('user_name','')
		user.user_last_name = request.form.get('user_last_name','')
		# user.date_joined = request.form.get('date_joined','')
		# user.last_visited = request.form.get('last_visited','')
		# user.friends = request.form.get('friends','')
		# user.friends[]

		user.user_friends = []		
		userfriends = request.form.get('user_friends', '')
		
		for u in userfriends:
			friend = u
			user.user_friends.append(friend)

		user.user_friends = request.form.get('user_friends', '');

		#now need to save a user's friends list
		#workking versionnn
		# user_totalFriends = request.form.get('user_totalFriends','')
		
		#Do I need to loop through friends list to plug into array???
		#you have to push things into the array. Google how
		#with mongoengine's EmbeddedDocument

	# friends = models.User.objects()
	# if friends:
 
	# 	#list to hold ideas
	# 	array_of_friends = []
 
	# 	#prep data for json
	# 	for i in friends:
			
	# 		tmpFriends = {
	# 			'friends' : i.friends,
	# 		}
 
	# 		# insert idea dictionary into public_ideas list
	# 	array_of_friends.append( tmpFreinds )

			#end of for loop for friends array

		user.friends.friend_id = request.form.get('0id','')
		user.friends.friend_name = request.form.get('0name','')
		# print(user)
		user.save()	
		#save it

		return redirect('/')
		
	else:

		# user = models.User()
		# user.userid = request.form.get('userid','')
		# user.user_name = request.form.get('user_name','')
		# user.user_last_name = request.form.get('user_last_name','')
		# # user.date_joined = request.form.get('date_joined','')
		# # user.last_visited = request.form.get('last_visited','')
		# # user.friends = request.form.get('friends','')

		# print(user)
		# user.save()	#save it

		return redirect('/')	

		# # render the template
		# templateData = {
		# 	'users' : models.User.objects(),
		# 	'form' : user_form
		# }
		
		# # app.logger.debug(templateData)

		# return render_template('display_fb_friends.html', **templateData)

    #after they login, they go somewhere thats where
    #you get friends, save in databse 
    #this needs to happen in the backend not the frontend?
    #backend cloud service?

    #after they login, loop through all of their friends and check the database 
	#however you query mongo to see if user id is there 
	# graph = facebook.GraphAPI(oauth_access_token)
	# profile = graph.get_object("me")
	# friends = graph.get_connections("me", "friends")


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


# Display all ideas for a specific category
# @app.route("/category/<cat_name>")
# def by_category(cat_name):

# 	# try and get ideas where cat_name is inside the categories list
# 	try:
# 		ideas = models.Idea.objects(categories=cat_name)

# 	# not found, abort w/ 404 page
# 	except:
# 		abort(404)

# 	# prepare data for template
# 	templateData = {
# 		'current_category' : {
# 			'slug' : cat_name,
# 			'name' : cat_name.replace('_',' ')
# 		},
# 		'ideas' : ideas,
# 		'categories' : categories
# 	}

# 	# render and return template
# 	return render_template('category_listing.html', **templateData)


@app.route("/ideas/<idea_slug>")
def idea_display(idea_slug):

	# get idea by idea_slug
	try:
		ideasList = models.Idea.objects(slug=idea_slug)
	except:
		abort(404)

	# prepare template data
	templateData = {
		'idea' : ideasList[0]
	}

	# render and return the template
	return render_template('idea_entry.html', **templateData)


@app.route("/ideas/<idea_id>/comment", methods=['POST'])
def idea_comment(idea_id):

	name = request.form.get('name')
	comment = request.form.get('comment')

	if name == '' or comment == '':
		# no name or comment, return to page
		return redirect(request.referrer)

	#get the idea by id
	try:
		idea = models.Idea.objects.get(id=idea_id)
	except:
		# error, return to where you came from
		return redirect(request.referrer)

	# create comment
	comment = models.Comment()
	comment.name = request.form.get('name')
	comment.comment = request.form.get('comment')
	
	# append comment to idea
	idea.comments.append(comment)

	# save it
	idea.save()

	return redirect('/ideas/%s' % idea.slug)


@app.route('/data/destination')
def data_destination():
 
	# query for the ideas - return oldest first, limit 10
	destination = models.Idea.objects().order_by('+timestamp').limit(10)
 
	if destination:
		# list to hold ideas
		public_destination = []
 
		#prep data for json
		for i in destination:
			
			tmpDestination = {
				'creator' : i.creator,
				'title' : i.title,
				'idea' : i.idea,
				'timestamp' : str( i.timestamp )
			}
 
			# comments / our embedded documents
			tmpDestination['comments'] = [] # list - will hold all comment dictionaries
			
			# loop through idea comments
			for c in i.comments:
				comment_dict = {
					'name' : c.name,
					'comment' : c.comment,
					'timestamp' : str( c.timestamp )
				}
 
				# append comment_dict to ['comments']
				tmpDestination['comments'].append(comment_dict)
 
			# insert idea dictionary into public_ideas list
			public_destination.append( tmpDestination )
 
		# prepare dictionary for JSON return
		data = {
			'status' : 'OK',
			'destination' : public_destination
		}
 
		# jsonify (imported from Flask above)
		# will convert 'data' dictionary and set mime type to 'application/json'
		return jsonify(data)
 
	else:
		error = {
			'status' : 'error',
			'msg' : 'unable to retrieve destination'
		}
		return jsonify(error)
	

# slugify the title 
# via http://flask.pocoo.org/snippets/5/
_punct_re = re.compile(r'[\t !"#$%&\'()*\-/<=>?@\[\\\]^_`{|},.]+')
def slugify(text, delim=u'-'):
	# """Generates an ASCII-only slug."""
	result = []
	for word in _punct_re.split(text.lower()):
		result.extend(unidecode(word).split())
	return unicode(delim.join(result))

# Facebook Test for Python ---------------------------

# class FacebookTestCase(unittest.TestCase):
#     # """Sets up application ID and secret from environment."""
#     def setUp(self):
#         try:
#             self.app_id = os.environ["238836302966820"]
#             self.secret = os.environ["28d066bd5d8fd289625d8e2c984170ab"]
#         except KeyError:
#             raise Exception("FACEBOOK_APP_ID and FACEBOOK_SECRET "
#                             "must be set as environmental variables.")


# class TestGetAppAccessToken(FacebookTestCase):
#     # """
#     # Test if application access token is returned properly.

#     # Note that this only tests if the returned token is a string, not
#     # whether it is valid.

#     # """
#     def test_get_app_access_token(self):
#         token = facebook.get_app_access_token(self.app_id, self.secret)
#         assert(isinstance(token, str) or isinstance(token, unicode))

# # End FB test ---------------------------


# Instagram - CURRENTLY NOT WORKING ---------------------------

# # configure API
# instaConfig = {
# 	'client_id':os.environ.get('CLIENT_ID'),
# 	'client_secret':os.environ.get('CLIENT_SECRET'),
# 	'redirect_uri' : os.environ.get('http://localhost:5000/instagram_callback')
# }
# api = InstagramAPI(**instaConfig)

# @app.route('/instagram_display')
# def user_photos():

# 	# if instagram info is in session variables, then display user photos
# 	if 'instagram_access_token' in session and 'instagram_user' in session:
# 		userAPI = InstagramAPI(access_token=session['instagram_access_token'])
# 		recent_media, next = userAPI.user_recent_media(user_id=session['instagram_user'].get('id'),count=25)

# 		templateData = {
# 			'size' : request.args.get('size','thumb'),
# 			'media' : recent_media
# 		}

# 		return render_template('instagram_display.html', **templateData)
		
# 	else:

# 		return redirect('/connect')

# # Redirect users to Instagram for login
# @app.route('/connect')
# def main():

# 	url = api.get_authorize_url(scope=["likes","comments"])
# 	return redirect(url)

# # Instagram will redirect users back to this route after successfully logging in
# @app.route('/instagram_callback')
# def instagram_callback():

# 	code = request.args.get('code')

# 	if code:

# 		access_token, user = api.exchange_code_for_access_token(code)
# 		if not access_token:
# 			return 'Could not get access token'

# 		app.logger.debug('got an access token')
# 		app.logger.debug(access_token)

# 		# Sessions are used to keep this data 
# 		session['instagram_access_token'] = access_token
# 		session['instagram_user'] = user

# 		return redirect('/instagram_display') # redirect back to main page
		
# 	else:
# 		return "Uhoh no code provided"


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

	