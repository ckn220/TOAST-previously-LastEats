import os, datetime
import re
from flask import jsonify
from flask import Flask, request, render_template, redirect, abort
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

app = Flask(__name__)   # create our flask app
# app.config['CSRF_ENABLED'] = False

app.secret_key = os.environ.get('SECRET_KEY') # put SECRET_KEY variable inside .env file with a random string of alphanumeric characters
app.config['CSRF_ENABLED'] = False
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024 # 16 megabyte file upload

# --------- Database Connection ---------
# MongoDB connection to MongoLab's database
app.config['MONGODB_SETTINGS'] = {'HOST':os.environ.get('MONGOLAB_URI'),'DB': 'itptravels-7'}
app.logger.debug("Connecting to MongoLabs")
db = MongoEngine(app) # connect MongoEngine with Flask App

ALLOWED_EXTENSIONS = set(['png', 'jpg', 'jpeg', 'gif'])


# DO I NEED? NO LONGER RELEVANT
# hardcoded categories for the checkboxes on the form
categories = ['St. Petersburg','Johannesburg','Salzburg','Pittsburgh','Spitzberg','Vicksburg','Harrisburg','Hamburg','Brandenburg']


# --------- Routes ----------
# this is our main page
@app.route("/", methods=['GET','POST'])
def index():

	#PHOTO upload route section
	# get Idea form from models.py
	photo_upload_form = models.photo_upload_form(request.form)
	
	# if form was submitted and it is valid...
	if request.method == "POST" and photo_upload_form.validate():
		
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
		idea.categories = request.form.getlist('categories') # getlist will pull multiple items 'categories' into a list
					
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


			return redirect('/ideas/%s' % idea.slug)

		else:
			# return "uhoh there was an error " + uploaded_file.filename
			idea.save()
			return redirect('/ideas/%s' % idea.slug)


	else:
		# get existing images
		images = models.Idea.objects.order_by('-timestamp')
		
		# render the template
		templateData = {
			# 'images' : images,
			'ideas' : models.Idea.objects(),
			'form' : photo_upload_form,
			'categories' : categories,
		}

		# app.logger.debug(templateData)
		return render_template("main.html", **templateData)


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


# Display all ideas for a specific category
@app.route("/category/<cat_name>")
def by_category(cat_name):

	# try and get ideas where cat_name is inside the categories list
	try:
		ideas = models.Idea.objects(categories=cat_name)

	# not found, abort w/ 404 page
	except:
		abort(404)

	# prepare data for template
	templateData = {
		'current_category' : {
			'slug' : cat_name,
			'name' : cat_name.replace('_',' ')
		},
		'ideas' : ideas,
		'categories' : categories
	}

	# render and return template
	return render_template('category_listing.html', **templateData)


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
	"""Generates an ASCII-only slug."""
	result = []
	for word in _punct_re.split(text.lower()):
		result.extend(unidecode(word).split())
	return unicode(delim.join(result))



# --------- Server On ----------
# start the webserver
if __name__ == "__main__":
	app.debug = True
	
	port = int(os.environ.get('PORT', 5000)) # locally PORT 5000, Heroku will assign its own port
	app.run(host='0.0.0.0', port=port)



	