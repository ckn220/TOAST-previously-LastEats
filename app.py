import os
import datetime
import re
from flask import jsonify
from flask import Flask, request, render_template, redirect, abort, session, flash
from unidecode import unidecode

from werkzeug import secure_filename

# mongoengine database module
from flask.ext.mongoengine import MongoEngine

# import data models
import models

# Amazon AWS library
import boto

# Python Image Library
import StringIO

#facebook/python 
# import facebook
# import unittest

#instagram
import time
from instagram.client import InstagramAPI



# os.environ['DEBUSSY'] = '1'
# os.environ['FSDB'] = '1'



# FACEBOOK_APP_ID = os.environ["238836302966820"]
# FACEBOOK_SECRET = os.environ[["28d066bd5d8fd289625d8e2c984170ab"]



app = Flask(__name__)   # create our flask app
# app.config['CSRF_ENABLED'] = False

app.secret_key = os.environ.get('SECRET_KEY') # put SECRET_KEY variable inside .env file with a random string of alphanumeric characters
app.config['CSRF_ENABLED'] = False
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024 # 16 megabyte file upload
app.config['WTF_CSRF_SECRET_KEY'] = 'dflksdlkfsdlfjgldkf'

# --------- Database Connection ---------
# MongoDB connection to MongoLab's database
app.config['MONGODB_SETTINGS'] = {'HOST':os.environ.get('MONGOLAB_URI'),'DB': 'idea'}
app.logger.debug("Connecting to MongoLabs")
db = MongoEngine(app) # connect MongoEngine with Flask App

ALLOWED_EXTENSIONS = set(['png', 'jpg', 'jpeg', 'gif'])


# DO I NEED? NO LONGER RELEVANT
# hardcoded categories for the checkboxes on the form
#categories = ['St. Petersburg','Johannesburg','Salzburg','Pittsburgh','Spitzberg','Vicksburg','Harrisburg','Hamburg','Brandenburg']


# --------- Routes ----------
# this is our main page
@app.route("/", methods=['GET','POST'])
def index():

	#PHOTO upload route section
	# get Idea form from models.py
	photo_upload_form = models.photo_upload_form(request.form)
	
	# if form was submitted and it is valid...
	if request.method == "POST":

		# if not saving to database, check photo module ---- and photo_upload_form.validate()

		uploaded_file = request.files['fileupload']
		# app.logger.info(file)
		# app.logger.info(file.mimetype)
		# app.logger.info(dir(file))
		
		# Uploading is fun
		# 1 - Generate a file name with the datetime prefixing filename
		# 2 - Connect to s3
		# 3 - Get the s3 bucket, put the file
		# 4 - After saving to s3, save data to database
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
					
		# idea.save() # save it
			
			# redirect to the new idea page
		# return redirect('/ideas/%s' % idea.slug)

		if uploaded_file and allowed_file(uploaded_file.filename):
			# return "upload file"
			# create filename, prefixed with datetime
			now = datetime.datetime.now()
			filename = now.strftime('%Y%m%d%H%M%s') + "-" + secure_filename(uploaded_file.filename)
			# thumb_filename = now.strftime('%Y%m%d%H%M%s') + "-" + secure_filename(uploaded_file.filename)

			# connect to s3
			s3conn = boto.connect_s3(os.environ.get('AWS_ACCESS_KEY_ID'),os.environ.get('AWS_SECRET_ACCESS_KEY'))

			# open s3 bucket, create new Key/file
			# set the mimetype, content and access control
			b = s3conn.get_bucket(os.environ.get('AWS_BUCKET')) # bucket name defined in .env
			
			k = b.new_key(b) # create a new Key (like a file)
			k.key = filename # set filename
			k.set_metadata("Content-Type", uploaded_file.mimetype) # identify MIME type
			k.set_contents_from_string(uploaded_file.stream.read()) # file contents to be added
			k.set_acl('public-read') # make publicly readable

			# if content was actually saved to S3 - save info to Database
			if k and k.size > 0:
				
				# submitted_image = models.Image()
				# submitted_image.title = request.form.get('title')
				# submitted_image.description = request.form.get('description')
				# submitted_image.postedby = request.form.get('postedby')
				# submitted_image.filename = filename # same filename of s3 bucket file
				# submitted_image.save()
				
				idea.filename = filename
				idea.save()	#save it


			return redirect('/ideas/%s' % idea.slug)	#if you make recent_submissions = DATA

		else:
			# return "uhoh there was an error " + uploaded_file.filename
			idea.save()
			return redirect('/ideas/%s' % idea.slug) 	#if you make recent_submissions = DATA


	else:
		# get existing images
		images = models.Idea.objects.order_by('-timestamp')
		
		# render the template
		templateData = {
			# 'images' : images,
			'ideas' : models.Idea.objects(),
			'form' : photo_upload_form,
			#'categories' : categories,
		}

		# app.logger.debug(templateData)
		return render_template("main.html", **templateData)		#if you make recent_submissions = DATA 


		        #OLD REGULAR FORM ROUTE INFO

				# else:

				# 	# for form management, checkboxes are weird (in wtforms)
				# 	# prepare checklist items for form
				# 	# you'll need to take the form checkboxes submitted
				# 	# and idea_form.categories list needs to be populated.
				# 	if request.method=="POST" and request.form.getlist('categories'):
				# 		for c in request.form.getlist('categories'):
				# 			idea_form.categories.append_entry(c)


					
					


#MORE PHOTO 
@app.route('/delete/<imageid>')
def delete_image(imageid):
        
        image = models.Image.objects.get(id=imageid)
        if image:

                # delete from s3
        
                # connect to s3
                s3conn = boto.connect_s3(os.environ.get('AWS_ACCESS_KEY_ID'),os.environ.get('AWS_SECRET_ACCESS_KEY'))

                # open s3 bucket, create new Key/file
                # set the mimetype, content and access control
                bucket = s3conn.get_bucket(os.environ.get('AWS_BUCKET')) # bucket name defined in .env
                k = bucket.new_key(bucket)
                k.key = image.filename
                bucket.delete_key(k)

                # delete from Mongo        
                image.delete()

                return redirect('/')

        else:
                return "Unable to find requested image in database."



@app.errorhandler(404)
def page_not_found(error):
    return render_template('404.html'), 404

def allowed_file(filename):
    return '.' in filename and \
           filename.lower().rsplit('.', 1)[1] in ALLOWED_EXTENSIONS
#END OF PHOTO






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

	


    # error = None
    # if request.method == 'POST':
    #     if valid_login(request.form['username'],
    #                    request.form['password']):
    #         return log_the_user_in(request.form['username'])
    #     else:
    #         error = 'Invalid username/password'
    # # the code below is executed if the request method
    # # was GET or the credentials were invalid
    	return render_template('login.html')



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



@app.errorhandler(404)
def page_not_found(error):
    return render_template('404.html'), 404


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







# Instagram ---------------------------

# configure API
instaConfig = {
	'client_id':os.environ.get('5bffa3e90cb04175bc57531e40a6acc2'),
	'client_secret':os.environ.get('4e99ce79340a4fb49cccd9981766c07b'),
	'redirect_uri' : os.environ.get('http://localhost:5000/')
}
api = InstagramAPI(**instaConfig)

@app.route('/')
def user_photos():

	# if instagram info is in session variables, then display user photos
	if 'instagram_access_token' in session and 'instagram_user' in session:
		userAPI = InstagramAPI(access_token=session['instagram_access_token'])
		recent_media, next = userAPI.user_recent_media(user_id=session['instagram_user'].get('id'),count=25)

		templateData = {
			'size' : request.args.get('size','thumb'),
			'media' : recent_media
		}

		return render_template('display.html', **templateData)
		

	else:

		return redirect('/connect')

# Redirect users to Instagram for login
@app.route('/connect')
def main():

	url = api.get_authorize_url(scope=["likes","comments"])
	return redirect(url)

# Instagram will redirect users back to this route after successfully logging in
@app.route('/instagram_callback')
def instagram_callback():

	code = request.args.get('code')

	if code:

		access_token, user = api.exchange_code_for_access_token(code)
		if not access_token:
			return 'Could not get access token'

		app.logger.debug('got an access token')
		app.logger.debug(access_token)

		# Sessions are used to keep this data 
		session['instagram_access_token'] = access_token
		session['instagram_user'] = user

		return redirect('/') # redirect back to main page
		
	else:
		return "Uhoh no code provided"


#Redundant???
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
	app.debug = True

	# unittest.main()	#FB Test

	port = int(os.environ.get('PORT', 5000)) # locally PORT 5000, Heroku will assign its own port
	app.run(host='0.0.0.0', port=port)



	