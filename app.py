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

from PIL import Image, ImageOps
from StringIO import StringIO

#instagram
# import time
# from instagram.client import InstagramAPI
import facebook
import mongoScripts

import sys
reload(sys)  # Reload does the trick!
sys.setdefaultencoding('UTF8')

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
	
	ip = ''
	if 'x-forwarded-for' in request.headers:
		ip = request.headers['x-forwarded-for']
	
	lat = None
	try:
		[lat, lng] = ipToLatLng(ip)
	except:
		print 'IP ERROR'
		
	if lat:
		locationIdea = models.Idea.objects(point__near=[lng, lat], complete = 1, deleted = 0).first()
	else:
		locationIdea = models.Idea.objects(complete = 1, deleted = 0, full_city = 'New York, NY').first()
		
	
	ideas = []
	friendIds = []
	for item in models.Idea.objects(complete = 1, deleted = 0).order_by('-timestamp')[:8]:
		item.display_city = ','.join(item.full_city.split(',')[:2])
		ideas.append(item)
		friendIds.append(item.userid)
	
	friends = {}
	for friend in models.User.objects(userid__in = friendIds).only('picture','userid'):
		friends[friend.userid] = friend
	
	if request.base_url == 'http://lasteats-dev.herokuapp.com/' or request.base_url == 'http://localhost:5000/' or request.base_url == 'http://192.168.1.2:5000/':
		if 'userid' in request.args:
			resp = make_response(redirect('/newsfeed'))
			resp.set_cookie('userid', request.args['userid'])
			return resp
		else:
			users = models.User.objects()
			templateData = {'users': users,
						'fbookId' : FACEBOOK_APP_ID,
						'ideas': ideas,
						'friends': friends,
						'locationIdea': locationIdea,
						'ip': ip}
			return render_template("index.html", **templateData)
	
	
	templateData = {'fbookId' : FACEBOOK_APP_ID,
				'ideas': ideas,
				'friends': friends,
				'locationIdea': locationIdea,
				'ip': request.remote_addr}
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
			addUser(request.cookies['fbook_auth_old'])
			
		user = models.User.objects(userid = request.cookies['userid']).first()
		user.last_visited = datetime.datetime.now()
		user.save()
		
		if (datetime.datetime.now() - user.picture_update).days > 7:
			user = update_user(user)
			
		templateData = {'user': user}
		return render_template("newsfeed.html", **templateData)

def update_user(user):
	graph = facebook.GraphAPI(str(FACEBOOK_APP_ID) + '|' + str(FACEBOOK_SECRET))
	user.picture = graph.get_profile(user.userid)['data']['url']
	user.picture_update = datetime.datetime.now()
	
	f = graph.get_connections(str(user.userid), connection_name = 'friends?fields=installed,name,picture')
	friends = []
	all_friends = []
	for id in f['data']:
		all_friends.append({'id': id['id'], 'name': id['name'], 'picture': id['picture']['data']['url']})
		if 'installed' in id:
			friends.append(id['id'])
	
	userFriends = models.UserFriends.objects(userid = user.userid).first()
	userFriends.all_friends = all_friends
	userFriends.save()
	
	user.save()
	
	return user

@app.route("/browse", methods=['GET','POST'])
def browse():
	
	if request.method == "POST":
		return get_newsfeed(request, 'browse')
	else:
		templateData = {}
		return render_template("browse.html", **templateData)
	
@app.route("/pinned", methods=['GET','POST'])
def pinned():
	cookie_check = checkCookies(request, '/newsfeed')
	if cookie_check != None:
		return cookie_check
	
	if request.method == "POST":
		return get_newsfeed(request, 'newsfeed', 'saved')
	else:
		
		user = models.User.objects(userid = request.cookies['userid']).first()
		
		templateData = {'user': user}
		return render_template("pinned.html", **templateData)

def get_newsfeed(request, path, type = None):
	offset = 0
	if 'offset' in request.form:
		offset = int(request.form.get('offset'))
	
	lat = None
	lng = None
	try:
		lat = float(request.form.get('lat'))
		lng = float(request.form.get('lng'))
	except:
		print 'LAT LNG FAIL!!!'
		
	if 'type' in request.form:
		type = request.form.get('type')
	
	user = None
	current_user = None
	if 'userid' in request.cookies:
		current_user = request.cookies['userid']
		user = models.User.objects(userid = request.cookies['userid']).first()
		
	if path == 'newsfeed' and type != 'all':
		if type == 'saved':
			ideas = models.Idea.objects(id__in = user.saves, complete = 1, deleted = 0)[offset:20+offset]
		elif type == 'new':
			ideas = models.Idea.objects(complete = 1, deleted = 0).order_by('-timestamp')[offset:20+offset]
		elif type == 'hot':
			if lat:
				ideas = models.Idea.objects(like_count__gte = 4, point__near=[lng, lat], complete = 1, deleted = 0)[offset:20+offset]
			else:
				ideas = models.Idea.objects(like_count__gte = 4, complete = 1, deleted = 0)[offset:20+offset]
		elif lat:
			ideas = models.Idea.objects(userid__in = user.friends, point__near=[lng, lat], complete = 1, deleted = 0)[offset:20+offset]
		else:
			ideas = models.Idea.objects(userid__in = user.friends, complete = 1, deleted = 0).order_by('-timestamp')[offset:20+offset]
			
	else:
		if lat:
			ideas = models.Idea.objects(point__near=[lng, lat], complete = 1, deleted = 0)[offset:20+offset]
		else:
			ideas = models.Idea.objects(complete = 1, deleted = 0).order_by('-timestamp')[offset:20+offset]
	
	templateData = newsfeedData(ideas, lat, lng)
	templateData['user'] = user
	templateData['current_user'] = current_user
	
	if type == 'new' and lat:
		templateData['ideaIds'] = sorted(templateData['ideaIds'], key=lambda x: float(templateData['ideas'][x].distance))
		
	return render_template("newsfeed_content.html", **templateData)

def newsfeedData(ideas, lat = None, lng = None):
	idea_list = {}
	idea_id_list = []
	friend_list = []
	for row in ideas:
		if lat:
			row.distance = '%.1f' % calcDist(lat, lng, row.point['coordinates'][1], row.point['coordinates'][0])
		idea_list[str(row.id)] = row
		idea_id_list.append(str(row.id))
		friend_list.append(row.userid)
	
	comments = {}
	for row in models.Comment.objects(ideaid__in = idea_id_list):
		if row.ideaid not in comments:
			comments[row.ideaid] = []
		comments[row.ideaid].append(row)
		friend_list.append(row.userid)
		
	friends = {}
	for row in models.User.objects(userid__in = friend_list):
		friends[row.userid] = row
		
	return {'ideas': idea_list,
			'ideaIds' : idea_id_list,
			'friends': friends,
			'comments': comments}

def addUser(auth):
	graph = facebook.GraphAPI(auth)
	me = graph.get_object('me')
	f = graph.get_connections(me['id'], connection_name = 'friends?fields=installed,name,picture')
	friends = []
	all_friends = []
	for id in f['data']:
		all_friends.append({'id': id['id'], 'name': id['name'], 'picture': id['picture']['data']['url']})
		if 'installed' in id:
			friends.append(id['id'])
	
	picture = graph.get_profile(me['id'])['data']['url']
	
	email = ''
	if 'email' in me:
		email = me['email']
		
	user = models.User(userid = me['id'], user_name = me['first_name'], user_last_name = me['last_name'], date_joined = datetime.datetime.now(), 
					last_visited = datetime.datetime.now(), friends = friends, picture = picture, email = email)
	user.save()
	
	userFriends = models.UserFriends(userid = me['id'], all_friends = all_friends)
	userFriends.save()
	
	#Update each other user already in the database
	for friendUser in models.User.objects(userid__in = friends):
		friendUser.friends.append(user.userid)
		friendUser.save()

@app.route("/last_eat_entry", methods=['GET'])
def old_last_eat_entry():
	if 'id' not in request.args:
		if 'userid' in request.cookies:
			return redirect('/newsfeed')
		else:
			return redirect('/browse')
	
	return redirect('/last_eat_entry/'+request.args['id'])
											
@app.route("/last_eat_entry/<id>", methods=['GET','POST','DELETE'])
def last_eat_entry(id):
	if not models.Idea.objects(id = id, complete = 1, deleted = 0).first():
		if 'userid' in request.cookies:
			return redirect('/newsfeed')
		else:
			return redirect('/browse')
	
	if request.method == "POST":
		cookie_check = checkCookies(request, "/last_eat_entry")
		if cookie_check != None:
			return cookie_check
		
		user = models.User.objects(userid = request.cookies['userid']).first()
		comment = request.form.get('comment')
		c = models.Comment(userid = user.userid, ideaid = id, seen = 0, comment_string = comment)
		c.save()
		
		friendid = models.Idea.objects(id = id).only('userid').first()
		if friendid != user.userid:
			friend = models.User.objects(userid = friendid.userid).only('notify_count').first()
			friend.notify_count += 1
			friend.save()
		
		templateData = {'comment': c, 'user': user}
		return render_template("comment.html", **templateData)
	
	elif request.method == "DELETE":
		id = request.form.get('id')
		idea = models.Comment.objects(id = id).first()
		idea.deleted = 1
		idea.save()
		return ''
		
	else:
		idea = models.Idea.objects(id = id, complete = 1, deleted = 0).first()
		#idea = get_instagram_photo(idea)
		
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
		
		days = ['Mon: ','Tue: ','Wed: ','Thur: ','Fri: ','Sat: ','Sun: ']
		for i in range(len(idea.hours)):
			for j in range(len(idea.hours[i])):
				if idea.hours[i][j]['start'] == '+0000': idea.hours[i][j]['start'] = '2400'
				if int(idea.hours[i][j]['start']) > 1200:
					start = str(int(idea.hours[i][j]['start']) - 1200)
					start = start[:-2] + ':' + start[-2:]
					start += 'pm'
				else:
					start = idea.hours[i][j]['start']
					start = start[:-2] + ':' + start[-2:]
					start += 'am'
				days[i] += start + ' - '
				
				if idea.hours[i][j]['end'] == '+0000': idea.hours[i][j]['end'] = '2400'
				if int(idea.hours[i][j]['end']) > 1200:
					end = str(int(idea.hours[i][j]['end']) - 1200)
					end = end[:-2] + ':' + end[-2:]
					end += 'pm'
				else:
					end = idea.hours[i][j]['end']
					end = end[:-2] + ':' + end[-2:]
					end += 'am'
				days[i] += end + '  '
				
		tags = {}
		for row in models.Tag.objects(ideaid = idea.id):
			if row.type not in tags:
				tags[row.type] = []
			tags[row.type].append(row)
		
		first = False
		if 'first' in request.args:
			first = request.args.get('first')
		
		templateData = {'current_user': current_user,
					'idea' : idea,
					'idea_id' : str(idea.id),
					'user': user,
					'friend': friend,
					'friends': friends,
					'comments': comments,
					'days': days,
					'tags':tags,
					'first':first}
		
		return render_template("last_eat_entry.html", **templateData)

@app.route("/removetag/<id>/<type>/<text>/", methods=['DELETE'])
def remove_tag(id, type, text):
	if request.method == "DELETE":
		tag = models.Tag.objects(ideaid = id, type = type, text = text).first()
		if tag:
			tag.delete()
			return 'Success'
	return 'Fail'


@app.route("/love_idea", methods=['POST','DELETE'])
def love_idea():
	if request.method == "POST":
		id = request.form.get('id')
		userid = request.cookies['userid']
		
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
		
		user = models.User.objects(userid = request.cookies['userid']).first()
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
		lat = None
		lng = None
		try:
			lat = float(request.form.get('lat'))
			lng = float(request.form.get('lng'))
		except:
			print 'LAT LNG FAIL!!!'
		
		if lat:
			ideas = models.Idea.objects(userid = request.cookies['userid'], point__near=[lng, lat], complete = 1, deleted = 0)
		else:
			ideas = models.Idea.objects(userid = request.cookies['userid'], complete = 1, deleted = 0)
		
		templateData = {'ideas': ideas}
		return render_template("profile_content.html", **templateData)
	
	elif request.method == "DELETE":
		id = request.form.get('id')
		idea = models.Idea.objects(id = id).first()
		idea.deleted = 1
		idea.save()
		
		return ''
		
	else:
		user = models.User.objects(userid = request.cookies['userid']).first()
		ideas = models.Idea.objects(userid = user.userid, complete = 1, deleted = 0).order_by('-timestamp')
		
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

@app.route("/friend_profile/<id>", methods=['GET','POST'])
def friend_profile(id):
	
	if not models.User.objects(userid = id).first():
		return redirect('my_friends')
	
	friend = models.User.objects(userid = id).first()
	
	if request.method == "POST":
		user = None
		current_user = None
		if 'userid' in request.cookies:
			current_user = request.cookies['userid']
			user = models.User.objects(userid = request.cookies['userid']).first()
			
		friend = models.User.objects(userid = id).first()
		lat = None
		lng = None
		try:
			lat = float(request.form.get('lat'))
			lng = float(request.form.get('lng'))
		except:
			pass
		
		if lat:
			ideas = models.Idea.objects(userid = friend.userid, point__near=[lng, lat], complete = 1, deleted = 0)
		else:
			ideas = models.Idea.objects(userid = friend.userid, complete = 1, deleted = 0)
		idea_list = {}
		idea_id_list = []
		friend_list = []
		
		templateData = newsfeedData(ideas, lat, lng)
		templateData['current_user'] = current_user
		templateData['user'] = user
		templateData['friend'] = friend
		
		return render_template("newsfeed_content.html", **templateData)

	else:
		templateData = {'friend': friend}
		
		return render_template("friend_profile.html", **templateData)

@app.route("/map", methods=['GET', 'POST'])
def map():
	cookie_check = checkCookies(request, '/map')
	if cookie_check != None:
		return cookie_check
	
	if request.method == "POST":
		lat = None
		currentCity = None
		try:
			lat = float(request.form.get('lat'))
			lng = float(request.form.get('lng'))
			currentCity = models.Idea.objects(point__near=[lng, lat], complete = 1, deleted = 0).only('full_city').first().full_city
			currentCity = ','.join(currentCity.full_city.split(',')[:2])
		except:
			currentCity = models.Idea.objects(complete = 1, deleted = 0, full_city = 'New York, NY').first()
			currentCity = ','.join(currentCity.full_city.split(',')[:2])
			print 'LAT LNG FAIL!!!'
		
		user = models.User.objects(userid = request.cookies['userid']).first()
		
		ideas = []
		names = []
		ids = []
		for row in models.Idea.objects(point__near=[lng, lat], complete = 1, deleted = 0).all():
			if row.restaurant_name in names:
				row.filter = 'Multiple Reccomendations'
				ideas.append(row)
				ids.append(row.id)
			else:
				names.append(row.restaurant_name)
			
		for row in models.Idea.objects(id__nin = ids, userid__in = user.friends, point__near=[lng, lat], complete = 1, deleted = 0).all():
			row.filter = 'Friends'
			ideas.append(row)
		for row in models.Idea.objects(like_count__lt = 2, userid__nin = user.friends, point__near=[lng, lat], complete = 1, deleted = 0).all():
			row.filter = 'Newest'
			ideas.append(row)
		
		friendids = set([])
		ideaids = []
		photos = {}
		tags = {}
		for row in ideas:
			friendids.add(row.userid)
			ideaids.append(str(row.id))
		for row in  models.User.objects(userid__in = list(friendids)).only('picture','userid'):
			photos[row.userid] = row.picture
		for row in models.Tag.objects(type__in = ['Type','Price'], ideaid__in = ideaids):
			if row.ideaid not in tags:
				tags[row.ideaid] = {}
			tags[row.ideaid][row.type] = row.text
			
		data = []
		for row in ideas:
			data.append({'lat':row.point['coordinates'][1], 'lng':row.point['coordinates'][0], 
						'title':row.restaurant_name, 'id':str(row.id),
						'photo':row.filename['url'], 'filter':row.filter, 'user':photos[row.userid],
						'type': tags.get(row.id,{}).get('Type',''), 'price': tags.get(row.id,{}).get('Price',''),
						'city': ','.join(row.full_city.split(',')[:2])})
		
		return jsonify(**{'data':data, 'currentCity':currentCity})
		
	else:
		type = request.args.get('type','')
		filter = request.args.get('filter','')
		price = request.args.get('price','')
		
		types = [u'Caribbean', u'Vietnamese', u'Middle Eastern', u'Brunch/American', u'Everything', u'Pub', 
				u'Brewery', u'Pizza', u'Japanese/Sushi', u'Latin', u'Deli', u'Dessert', u'American/Pub', 
				u'Southern', u'French', u'Thai', u'Tapas', u'Cuban', u'Seafood', u'Breweries', u'Greek', 
				u'American', u'Steakhouse', u'BBQ', u'Italian', u'Mexican', u'Sushi', u'Mediterranean', 
				u'Japanese', u'Diet: Vegitarian', u'Delis', u'Breweries/Pub', u'Asian', u'Spanish', u'Breakfast']
		types.sort()
		
		cities = set([])
		for row in models.Idea.objects(complete = 1, deleted = 0).only('full_city').all():
			cities.add(','.join(row.full_city.split(',')[:2]))
			
		cities = list(cities)
		cities.sort()
		templateData = {'types':types, 'type':type,'filter':filter, 'price':price, 'cities':cities}
		return render_template("map.html", **templateData)
	
	
@app.route("/city_filter", methods=['GET'])
def city_filter():
	ordered_cities = []
	city_count = {}
	cities = {}
	user = None
	if 'userid' in request.cookies:
		user = models.User.objects(userid = request.cookies['userid']).first()

	ideas = models.Idea.objects(complete = 1, deleted = 0).order_by('-timestamp')
	
	for idea in ideas:
		display_city = ','.join(idea.full_city.split(',')[:2])
		if display_city not in cities:
			cities[display_city] = display_city
			
			ordered_cities.append(display_city)
			city_count[display_city] = models.Idea.objects(full_city__contains = display_city, complete = 1, deleted = 0).count()
			
	ordered_cities.sort()
	templateData = {'user': user,
				'list': ordered_cities,
				'count': city_count,
				'cities': cities}
	return render_template("filter.html", **templateData)

@app.route("/city", methods=['GET', 'POST'])
def city():
	
	if request.method == "POST":
		user = None
		city = request.form.get('city')
		
		lat = None
		lng = None
		try:
			lat = float(request.form.get('lat'))
			lng = float(request.form.get('lng'))
		except:
			print 'LAT LNG FAIL!!!'
		
		s = ''
		if 'userid' in request.cookies:
			user = models.User.objects(userid = request.cookies['userid']).first()
			if lat:
				ideas = models.Idea.objects(userid__in = user.friends, full_city__contains = city, complete = 1, deleted = 0, point__near=[lng, lat])
			else:
				ideas = models.Idea.objects(userid__in = user.friends, full_city__contains = city, complete = 1, deleted = 0).order_by('-timestamp')
			templateData = newsfeedData(ideas, lat, lng)
			templateData['user'] = user
			templateData['city'] = city
			if len(ideas) > 0:
				s = render_template("newsfeed_content.html", **templateData)
			
			if lat:
				ideas = models.Idea.objects(userid__nin = user.friends, full_city__contains = city, complete = 1, deleted = 0, point__near=[lng, lat])
			else:
				ideas = models.Idea.objects(userid__nin = user.friends, full_city__contains = city, complete = 1, deleted = 0).order_by('-timestamp')
		else:
			if lat:
				ideas = models.Idea.objects(full_city__contains = city, complete = 1, deleted = 0, point__near=[lng, lat])
			else:
				ideas = models.Idea.objects(full_city__contains = city, complete = 1, deleted = 0).order_by('-timestamp')
		
		templateData = newsfeedData(ideas, lat, lng)
		templateData['user'] = user
		templateData['city'] = city
		s += render_template("newsfeed_content.html", **templateData)
		
		return s
		
	else:
		user = None
		if 'userid' in request.cookies:
			user = models.User.objects(userid = request.cookies['userid']).first()
		
		city = request.args['name']
		templateData = {'user': user, 'city': city}
		return render_template("city.html", **templateData)


@app.route("/price_filter", methods=['GET'])
def price_filter():
	prices = {1:[],2:[],3:[],4:[]}
	ordered_prices = [1,2,3,4]
	display_prices = {1:'$',2:'$$',3:'$$$',4:'$$$$'}
	user = models.User.objects(userid = request.cookies['userid']).first()
	ideas = models.Idea.objects(userid__in = user.friends, complete = 1, deleted = 0).order_by('-timestamp')
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
	c = models.Comment.objects(ideaid__in = ids, userid__ne = userid, seen = 0).order_by('-timestamp')
	
	comments = []
	for row in c:
		friend_ids.append(row.userid)
		idea_ids.append(row.ideaid)
		comments.append(row)
		row.seen = 1
		row.save()
		
	friends = {}
	for row in models.User.objects(userid__in = friend_ids):
		friends[row.userid] = row
	ideas = {}
	for row in models.Idea.objects(id__in = idea_ids):
		ideas[str(row.id)] = row
		
	user = models.User.objects(userid = request.cookies['userid']).first()
	user.notify_count = 0
	user.save()
	
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
		friends = models.User.objects(userid__in = user.friends).order_by('user_name')
		
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
	if request.method == "POST":
		full_city = request.form.get('city').replace(' City','').replace(' city','')
		city = full_city.split(',')[0]
		
		checkCity = None
		if 'userid' in request.cookies:
			checkCity = models.Idea.objects(userid = request.cookies['userid'], full_city = full_city, complete = 1, deleted = 0).first()
		
		warned = request.form.get('warned')
		
		if not checkCity or warned == 'true':
			if checkCity:
				checkCity.deleted = 1
				checkCity.save()
			lat = float(request.form.get('addressLat'))
			lng = float(request.form.get('addressLng'))
			
			userid = ''
			if 'userid' in request.cookies:
				userid = request.cookies['userid']
				
			idea = models.Idea(title = city, full_city = full_city, restaurant_name = request.form.get('addressName'),
							point = [lng, lat], userid = userid)
			#cost = request.form.get('cost'), 
			
			idea = get_instagram_id(idea, lat, lng)
			
			if 'requestid' in request.form:
				req = models.Request.objects(id = request.form.get('requestid')).first()
				if req and 'userid' in request.cookies and request.cookies['userid'] in req.friends:
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
		
		user = None
		if 'userid' in request.cookies:
			user = models.User.objects(userid = request.cookies['userid']).first()
			
		templateData = {'user': user,
					'req': req}
		return render_template("add_last_eats.html", **templateData)

@app.route("/add_last_eats_next", methods=['GET','POST'])
def add_last_eats_next():
	
	if request.method == "POST":
		id = request.form.get('id')
		idea = models.Idea.objects(id = id).first()
		idea.idea = request.form.get('idea')
		idea.save()
		
		d = {'id' : str(idea.id)}
		return jsonify(**d)
	
	else:
		user = None
		if 'userid' in request.cookies:
			user = models.User.objects(userid = request.cookies['userid']).first()
			
		id = request.args['id']
		templateData = {'user': user,'id':id}
		return render_template("add_last_eats_next.html", **templateData)

@app.route("/add_last_eats_next_next", methods=['GET','POST'])
def add_last_eats_next_next():
	if request.method == "POST":
		id = request.form.get('id')
		idea = models.Idea.objects(id = id).first()
		idea.order = request.form.get('order')
		idea.save()
		
		d = {'id' : str(idea.id)}
		return jsonify(**d)
	
	else:
		user = None
		if 'userid' in request.cookies:
			user = models.User.objects(userid = request.cookies['userid']).first()
			
		id = request.args['id']
		templateData = {'user': user, 'id':id}
		return render_template("add_last_eats_next_next.html", **templateData)

@app.route("/add_last_eats_tags", methods=['GET','POST'])
def add_last_eats_tags():
	tagSets = {u'Vibe': set([u'Trendy', u'Hip', u'Upscale', u'Laid Back', u'Intimate']),
		u'Price': set([u'Bang for the Buck', u'Pricey']),
		u'Great for': set([u'Lunch', u'Breakfast', u'Brunch', u'Dinner', u'Dessert']),
		u'Diet': set([u'Gluten Free Options','Vegetarian Options']),
		u'Perks': set([u'Full Bar', u'Kid Friendly', u'Groups']),
		u'Attire': set([u'Casual', u'Formal']),
		u'Type': set([u'Indian',u'Caribbean', u'Vietnamese', u'Middle Eastern', u'Brunch/American', u'Everything', u'Pub', u'Brewery', 
					u'Pizza', u'Japanese/Sushi', u'Latin', u'Deli', u'Dessert', u'American/Pub', u'Southern', u'French', u'Thai', u'Tapas', 
					u'Cuban', u'Seafood', u'Breweries', u'Greek', u'American', u'Steakhouse', u'BBQ', u'Italian', u'Mexican', u'Sushi', 
					u'Mediterranean', u'Japanese', u'Diet: Vegitarian', u'Delis', u'Breweries/Pub', u'Asian', u'Spanish', u'Breakfast'])}
	
	tagList = list(tagSets['Type'])
	tagList.sort()
	tagSets['Type'] = tagList
	
	if request.method == "POST":
		id = request.form.get('id')
		idea = models.Idea.objects(id = id).first()
		
		for row in tagSets:
			print request.form.getlist(row)
			for text in request.form.getlist('tags['+row+'][]'):
				if not models.Tag.objects(ideaid = id, type = row, text = text).first():
					tag = models.Tag(ideaid = id, type = row, text = text)
					tag.save()
		idea.save()
		
		d = {'id' : str(idea.id)}
		return jsonify(**d)
	
	else:
		id = request.args['id']
		templateData = {'id':id, 'tagSets':tagSets}
		return render_template("add_last_eats_tags.html", **templateData)

@app.route("/add_last_eats_last", methods=['GET','POST'])
def add_last_eats_last():
	if request.method == "POST":
		image_suc = False
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
				
				file_string = uploaded_file.stream.read()
				
				image = Image.open(StringIO(file_string))
				image = ImageOps.fit(image, (600,600), Image.ANTIALIAS)
				
				filename = 'static/img/lasteatimg/' + filename
				image.save(filename)
				
				k = b.new_key(b) # create a new Key (like a file)
				k.key = filename # set filename
				k.set_metadata("Content-Type", uploaded_file.mimetype) # identify MIME type
				k.set_contents_from_filename(filename) # file contents to be added
				k.set_acl('public-read') # make publicly readable
				
				# if content was actually saved to S3 - save info to Database
				if k and k.size > 0:
					idea.filename = {'url': 'http://lasteats.s3-website-us-west-2.amazonaws.com/' + filename}
					
					image_suc = True
					
		if not image_suc:
			creator = request.form.get('creator')
			id = request.form.get('id')
			idea.filename = {'url':request.form.get('image'), 'creator':creator, 'id':id}
		
		
		if 'userid' not in request.cookies:
			if 'fbook_auth' in request.form:
				graph = facebook.GraphAPI(request.form.get('fbook_auth'))
				me = graph.get_object('me')
				x = models.User.objects(userid = me['id']).count()
				if x == 0:
					addUser(request.form.get('fbook_auth'))
				else:
					checkCity = models.Idea.objects(userid = me['id'], full_city = idea.full_city, complete = 1, deleted = 0).first()
					if checkCity:
						checkCity.deleted = 1
						checkCity.save()
				idea.complete = 1
				idea.userid = me['id']
				idea.save()
				
				resp = make_response(redirect('/last_eat_entry/'+str(idea.id)+'?first=true'))
				resp.set_cookie('fbook_auth_old', request.cookies['fbook_auth'])
				resp.set_cookie('fbook_auth', '', expires=0)
				resp.set_cookie('userid', me['id'])
				return resp
				
			else:
				return redirect('')
				
		else:
			if not idea.userid:
				checkCity = models.Idea.objects(userid = request.cookies['userid'], full_city = idea.full_city, complete = 1, deleted = 0).first()
				if checkCity:
					checkCity.deleted = 1
					checkCity.save()
				idea.userid = request.cookies['userid']
				
			idea.complete = 1
			idea.save()
			
			resp = make_response(redirect('/last_eat_entry/'+str(idea.id)+'?first=true'))
			return resp
	
	else:
		extrastep = True
		currentuser = None
		if 'userid' in request.cookies:
			currentuser = request.cookies['userid']
			
		id = request.args['id']
		idea = models.Idea.objects(id = id).first()
		templateData = {'id':id,
						'idea': idea,
						'currentuser':currentuser,
						'extrastep':extrastep,
						'fbookId' : FACEBOOK_APP_ID,}
		return render_template("add_last_eats_last.html", **templateData)


def get_instagram_id(idea, lat, lng):
	url = 'https://api.foursquare.com/v2/venues/search?ll='+str(lat)+','+str(lng)+'&query='+idea.restaurant_name+'&client_id='+FOURSQUARE_CLIENT_ID+'&client_secret='+FOURSQUARE_CLIENT_SECRET+'&v=20130609'
	response = requests.request("GET",url)
	data = json.loads(response.text)
	
	instagram_ids = []
	id_phones = {}
	id_address = {}
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
				
				id_phones[item['id']] = ''
				id_address[item['id']] = ''
				if 'phone' in data['response']['venues'][i]['contact']:
					id_address[item['id']] = data['response']['venues'][i]['location']['formattedAddress'][0]
					id_phones[item['id']] = data['response']['venues'][i]['contact']['phone']
				
		i += 1
	
	if len(instagram_ids) > 0:
		for row in instagram_ids:
			idea.filenames = []
			idea.instagram_id = row
			idea = get_instagram_photo(idea)
			if len(idea.filenames) > 0:
				url = 'https://api.foursquare.com/v2/venues/' + idea.instagram_id + '/hours?client_id=' + FOURSQUARE_CLIENT_ID + '&client_secret=' + FOURSQUARE_CLIENT_SECRET + '&v=20120609'
				response = requests.request("GET",url)
				data = json.loads(response.text)
				
				idea.phone = id_phones[idea.instagram_id]
				idea.address = id_address[idea.instagram_id]
				idea.hours = [[],[],[],[],[],[],[]]
				if 'popular' in data['response'] and 'timeframes' in data['response']['popular']:
					for row in data['response']['popular']['timeframes']:
						for day in row['days']:
							idea.hours[day-1] = row['open']
				
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


def ipToLatLng(ip):
	
	url = 'http://freegeoip.net/json/'+ ip
	
	response = requests.request("GET",url, timeout=0.5)
	
	data = json.loads(response.text) 
	
	return [data['latitude'], data['longitude']]
	

def userRequests(userid):
	user = models.User.objects(userid = userid).first()
	count = 0
	
	count += models.Request.objects(friends = request.cookies['userid']).count()
	
	ids = []
	for row in models.Request.objects(userid = request.cookies['userid']).only('id'):
		ids.append(str(row.id))
	
	count += models.Idea.objects(request_id__in = ids, seen = 0).count()
	
	if count > 0:
		return '(' + str(count) + ')'
	else:
		return ''


app.jinja_env.globals.update(userRequests=userRequests)

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


#mongoScripts.runAll(FACEBOOK_APP_ID, FACEBOOK_SECRET)
#mongoScripts.cleanAllFriends()

if __name__ == "__main__":
	# unittest.main()	#FB Test
	port = int(PORT) # locally PORT 5000, Heroku will assign its own port
	app.run(host='0.0.0.0', port=port, debug = True, use_reloader = False)
	
