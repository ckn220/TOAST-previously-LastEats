import os
import datetime
import time
import re
import math

from flask import jsonify
from flask import Flask, request, render_template, redirect, abort, session, flash, url_for

from unidecode import unidecode
from werkzeug.utils import secure_filename

from flask.ext.mongoengine import MongoEngine
import models
import StringIO

import requests
import json
import boto

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

AWS_BUCKET='lasteats'
AWS_ACCESS_KEY_ID='AKIAI3P2HEHI6EUEH6UQ'
AWS_SECRET_ACCESS_KEY='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'

PORT = int(os.environ.get("PORT", 5000))
#Instagram
INSTAGRAM_TOKEN = os.environ['access_token']
FOURSQUARE_CLIENT_ID = 'PVTLQK3ZVWOHDSH2TSKPMRS41R5LN2E4XVRC5T2VTSRRO3WC'
FOURSQUARE_CLIENT_SECRET = '2KSXRK2JY2VA0XV2F5JGYTYB2JYPUHMRYFG1ZSKITDUWDJ2X'
## End Env

UPLOAD_FOLDER = os.getcwd() + '\static\img\lasteatimg'
ALLOWED_EXTENSIONS = set(['png', 'jpg', 'jpeg', 'gif'])

app = Flask(__name__)   # create our flask app

app.secret_key = SECRET_KEY 
# put SECRET_KEY variable inside .env file with a random string of alphanumeric characters
app.config['DEBUG'] = True
app.config['CSRF_ENABLED'] = False
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024 # 16 megabyte file upload
app.config['WTF_CSRF_SECRET_KEY'] = 'dflksdlkfsdlfjgldkf'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

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
	
	ideas = []
	friendIds = []
	for item in models.Idea.objects(complete = 1).order_by('-timestamp')[:12]:
		item.display_city = ','.join(item.full_city.split(',')[:2])
		ideas.append(item)
		friendIds.append(item.userid)
	
	friends = {}
	for friend in models.User.objects(userid__in = friendIds).only('picture','userid'):
		friends[friend.userid] = friend
	
	if request.base_url == 'http://lasteats-dev.herokuapp.com/' or request.base_url == 'http://localhost:5000/':
		if 'userid' in request.args:
			resp = make_response(redirect('/newsfeed'))
			resp.set_cookie('userid', request.args['userid'])
			return resp
		else:
			users = models.User.objects()
			templateData = {'users': users,
						'fbookId' : FACEBOOK_APP_ID,
						'ideas': ideas,
						'friends': friends}
			return render_template("index.html", **templateData)
		
		
	templateData = {'fbookId' : FACEBOOK_APP_ID,
				'ideas': ideas,
				'friends': friends}
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
	offset = 0
	if 'offset' in request.form:
		offset = int(request.form.get('offset'))
	
	lat = float(request.form.get('lat', None))
	lng = float(request.form.get('lng', None))
	if 'type' in request.form:
		type = request.form.get('type')
	else:
		type = None
	
	if path == 'newsfeed' and type != 'all':
		user = models.User.objects(userid = request.cookies['userid']).first()
		
		if type == 'saved':
			ideas = models.Idea.objects(id__in = user.saves, complete = 1)[offset:20+offset]
		elif lat != None:
			ideas = models.Idea.objects(userid__in = user.friends, point__near=[lng, lat], complete = 1)[offset:20+offset]
		else:
			ideas = models.Idea.objects(userid__in = user.friends, complete = 1).order_by('-timestamp')[offset:20+offset]
			
	else:
		if lat != None:
			ideas = models.Idea.objects(point__near=[lng, lat], complete = 1)[offset:20+offset]
		else:
			ideas = models.Idea.objects(complete = 1).order_by('-timestamp')[offset:20+offset]
	
	idea_list = []
	friendList = []
	for row in ideas:
		idea_list.append(row)
		friendList.append(row.userid)
	
	friends = {}
	for row in models.User.objects(userid__in = friendList):
		friends[row.userid] = row
	
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
		c = models.Comment(userid = user.userid, ideaid = id, seen = 0, comment_string = comment)
		c.save()
		
		friendid = models.Idea.objects(id = id).only('userid').first()
		friend = models.User.objects(userid = friendid.userid).only('notify_count').first()
		friend.notify_count += 1
		friend.save()
		
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
		
		user = None
		if 'userid' in request.cookies:
			current_user = request.cookies['userid']
			user = models.User.objects(userid = request.cookies['userid']).first()
		else:
			current_user = None
		
		friend = models.User.objects(userid = idea.userid).first()
		
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
			return 'ADDED'
		else:
			idea.likes.remove(userid)
			idea.like_count = len(idea.likes)
			idea.save()
			return 'REMOVED'
		
@app.route("/save_idea", methods=['POST','DELETE'])
def save_idea():
	if request.method == "POST":
		id = request.form.get('id')
		userid = request.form.get('userid')
		
		user = models.User.objects(userid = userid).first()
		if id not in user.saves:
			user.saves.append(id)
			user.save()
			return 'ADDED'
		else:
			user.saves.remove(id)
			user.save()
			return 'REMOVED'
		

@app.route("/profile", methods=['GET','POST','DELETE'])
def profile():
	cookie_check = checkCookies(request, "/profile")
	if cookie_check != None:
		return cookie_check
	
	if request.method == "POST":
		lat = float(request.form.get('lat'))
		lng = float(request.form.get('lng'))
		
		ideas = models.Idea.objects(userid = request.cookies['userid'], point__near=[lng, lat], complete = 1)
		
		templateData = {'ideas': ideas}
		return render_template("profile_content.html", **templateData)
	
	elif request.method == "DELETE":
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
	friends = []
	fid = []
	for row in models.User.objects(userid__in = user.friends):
		friends.append(row)
		fid.append(row.userid)
	friends = sorted(friends, key=lambda x: x.user_name)
	
	all_friends = models.UserFriends.objects(userid = user.userid).first().all_friends
	all_friends = sorted(all_friends, key=lambda x: x['name'])
	
	templateData = {'friends': friends,
				'all_friends': all_friends[:20],
				'all_friends_hidden': all_friends[20:],
				'fid':fid}
	return render_template("my_friends.html", **templateData)

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
		return render_template("friend_profile_content.html", **templateData)

	else:
		id = request.args['friendid']
		friend = models.User.objects(userid = id).first()
		templateData = {'friend': friend}
		
		return render_template("friend_profile.html", **templateData)


@app.route("/city_filter", methods=['GET'])
def city_filter():
	#cities = {}
	ordered_cities = []
	city_count = []
	cities = {}
	user = None
	if 'userid' in request.cookies:
		user = models.User.objects(userid = request.cookies['userid']).first()
		ideas = models.Idea.objects(userid__in = user.friends, complete = 1).order_by('-timestamp')
	else:
		ideas = models.Idea.objects(complete = 1).order_by('-timestamp')

	for idea in ideas:
		if idea.full_city not in cities:
			#cities[idea.title] = []
			cities[idea.full_city] = ','.join(idea.full_city.split(',')[:2])
			
			ordered_cities.append(idea.full_city)
			if 'userid' in request.cookies:
				city_count.append(models.Idea.objects(userid__in = user.friends, full_city = idea.full_city, complete = 1).count())
			else:
				city_count.append(models.Idea.objects(full_city = idea.full_city, complete = 1).count())
			
		#cities[idea.title].append(idea)
	ordered_cities.sort()
	templateData = {'user': user,
				#'filter': cities,
				'list': ordered_cities,
				'count': city_count,
				'cities': cities}
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
	
	friend_ids = []
	idea_ids = []
	open_requests = []
	#Get open requests for your opinion
	for row in models.Request.objects(friends = request.cookies['userid']):
		open_requests.append(row)
		friend_ids.append(row.userid)
		
	#Requests that your friends have responded to
	requestIds = []
	for row in models.Request.objects(userid = request.cookies['userid']).only('id'):
		requestIds.append(str(row.id))
	requestIdeas = []
	for row in models.Idea.objects(request_id__in = requestIds):
		requestIdeas.append(row)
		friend_ids.append(str(row.userid))
	
	#Get comments for your last eat entries 
	ideas = models.Idea.objects(userid = userid).only('id')
	ids = []
	for idea in ideas:
		ids.append(str(idea.id))
	c = models.Comment.objects(ideaid__in = ids, seen = 0).order_by('-timestamp')
	
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
				'requestIdeas': requestIdeas,
				'open_requests': open_requests,
				'ideas': ideas,
				'comments': comments}
	return render_template("notify_content.html", **templateData)


@app.route("/le_requests", methods=['GET', 'POST'])
def le_requests():
	cookie_check = checkCookies(request, '/le_requests')
	if cookie_check != None:
		return cookie_check
	
	if request.method == "POST":
		city = request.form.get('city')
		lat = float(request.form.get('cityLat'))
		lng = float(request.form.get('cityLng'))
			
		title = city.split(',')[0]
		friends = request.form.getlist('friends[]')
		
		r = models.Request(title = title, full_city = city, userid = request.cookies['userid'], 
						friends = friends, point = [lng, lat])
		r.save()
		
		for friend in models.User.objects(userid__in = friends).only('notify_count'):
			friend.notify_count += 1
			friend.save()
		
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
	
	friend_ids = []
	open_requests = []
	for row in models.Request.objects(friends = request.cookies['userid']):
		open_requests.append(row)
		friend_ids.append(row.userid)
		
	ids = []
	r = []
	for row in models.Request.objects(userid = request.cookies['userid']):
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
	
	templateData = {'open_requests':open_requests,
			'requests': r,
			'requestIds': ids,
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
			
			if 'requestid' in request.form:
				req = models.Request.objects(id = request.form.get('requestid')).first()
				if req and request.cookies['userid'] in req.friends:
					idea.request_id = request.form.get('requestid')
					idea.seen = 0
					
					friend = models.User.objects(userid = req.userid).only('notify_count').first()
					friend.notify_count += 1
					friend.save()
					
					req.friends.remove(request.cookies['userid'])
					req.save()
					
			
			idea.save()
			if not idea.instagram_id:
				print 'NO INSTAGRAM PHOTOS FOUND FOR IDEA ' + str(idea.id)
			
			d = {'id' : str(idea.id)}
			return jsonify(**d)
		else:
			d = {'error' : 'You already have <b>'+checkCity.restaurant_name+'</b> as your Last Eats in <b>'+checkCity.title+'</b>.<br>If you continue it will overwrite your old entry.'}
			return jsonify(**d)
	else:
		req = None
		if 'requestid' in request.args:
			req = models.Request.objects(id = request.args['requestid']).first()
		
		user = models.User.objects(userid = request.cookies['userid']).first()
		templateData = {'user': user,
					'req': req}
		return render_template("add_last_eats.html", **templateData)

@app.route("/add_last_eats_next", methods=['GET','POST'])
def add_last_eats_next():
	cookie_check = checkCookies(request, '/add_last_eats_next')
	if cookie_check != None:
		return cookie_check
	
	if request.method == "POST":
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
		
		if 'picture' in request.files:
			uploaded_file = request.files['picture']
			
			# Uploading is fun
			# 1 - Generate a file name with the datetime prefixing filename
			# 2 - Connect to s3
			# 3 - Get the s3 bucket, put the file
			# 4 - After saving to s3, save data to database
			# get form data - create new idea
			
			if uploaded_file:
				# return "upload file"
				# create filename, prefixed with datetime
				now = datetime.datetime.now()
				filename = now.strftime('%Y%m%d%H%M%S%f') + "-" + secure_filename(uploaded_file.filename)
				# thumb_filename = now.strftime('%Y%m%d%H%M%s') + "-" + secure_filename(uploaded_file.filename)
				
				# connect to s3
				s3conn = boto.connect_s3(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
				
				# open s3 bucket, create new Key/file
				# set the mimetype, content and access control
				b = s3conn.get_bucket(AWS_BUCKET) # bucket name defined in .env
				
				k = b.new_key(b) # create a new Key (like a file)
				k.key = filename # set filename
				k.set_metadata("Content-Type", uploaded_file.mimetype) # identify MIME type
				k.set_contents_from_string(uploaded_file.stream.read()) # file contents to be added
				k.set_acl('public-read') # make publicly readable
				
				# if content was actually saved to S3 - save info to Database
				if k and k.size > 0:
					idea.filename = {'url': 'http://lasteats.s3-website-us-west-2.amazonaws.com/' + filename}
					
		else:
			creator = request.form.get('creator')
			id = request.form.get('id')
			idea.filename = {'url':request.form.get('image'), 'creator':creator, 'id':id}
			
		idea.complete = 1
		idea.save()
		
		resp = make_response(redirect('/profile'))
		return resp
	
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
	url = 'https://api.instagram.com/v1/locations/'+ idea.instagram_id +'/media/recent?access_token=' + INSTAGRAM_TOKEN + '&count=30'
	response = requests.request("GET",url)
	data = json.loads(response.text)
	if len(data['data']) > 0:
		idea.filename = {'url':data['data'][0]['images']['standard_resolution']['url'],'id':data['data'][0]['user']['id'],'creator':data['data'][0]['user']['username']}
		idea.filenames = []
		for row in data['data']:
			idea.filenames.append({'url':row['images']['standard_resolution']['url'],'id':row['user']['id'],'creator':row['user']['username']})
		
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

		
import math
def calcDist(lat1, lng1, lat2, lng2):
	earthRadius = 3958.75
	dLat = math.radians(lat2-lat1)
	dLng = math.radians(lng2-lng1)
	a = math.sin(dLat/2) * math.sin(dLat/2) +\
		math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *\
		math.sin(dLng/2) * math.sin(dLng/2)
	c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
	dist = earthRadius * c
	
	mileConversion = 1609 * 0.000621371
	dist = dist * mileConversion
	return dist

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
	
	

	