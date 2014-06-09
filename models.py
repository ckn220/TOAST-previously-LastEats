# mongoengine database module
# from mongoengine import *
# from datetime import datetime
# import logging

#new for photo upload
from mongoengine import *
from flask.ext.mongoengine import *
from flask.ext.mongoengine.wtf import model_form
from wtforms.fields import * # for our custom signup form
from flask.ext.mongoengine.wtf.orm import validators
from datetime import datetime


class Comment(Document):
	
	userid = mongoengine.StringField()
	ideaid = mongoengine.StringField()
	comment_string = mongoengine.StringField(max_length=140)
	
	timestamp = mongoengine.DateTimeField(default=datetime.now())
	

class Idea(Document):
	userid = mongoengine.StringField()
	complete = mongoengine.IntField(required=True, default=0)
	
	title = mongoengine.StringField(required=True)
	restaurant_name = mongoengine.StringField(required=True)
	
	point = mongoengine.PointField(required=True)
	
	cost = mongoengine.IntField()
	
	idea = mongoengine.StringField(verbose_name="What makes it great?")
	order = mongoengine.StringField(verbose_name="What would you order?")
	
	slug = mongoengine.StringField()
	instagram_id = mongoengine.StringField()
	filename = mongoengine.StringField()
	filenames = mongoengine.ListField()
	
	# Timestamp will record the date and time idea was created.
	timestamp = mongoengine.DateTimeField(default = datetime.now(), required=True)

#photo_form = model_form(Idea)


#new for photo upload
#class photo_upload_form(photo_form):
#    fileupload = FileField('Upload an image file', validators=[])

class Friend(mongoengine.EmbeddedDocument):
	#you have to push things into the array. Google how
	#with mongoengine's EmbeddedDocument

 	friend_id = mongoengine.IntField()
 	friend_name = mongoengine.StringField()


class User(Document):

	userid = mongoengine.StringField()
	user_name = mongoengine.StringField()
	user_last_name = mongoengine.StringField()
	
	picture = mongoengine.StringField()
	
	#This works with storing the data as a string, but we want it in json in array
	#user_friends = mongoengine.ListField()
	
	#need to play with this for structuring the data into an array - the formating, it doesn't like ListField
	# user_friends = mongoengine.ListField( mongoengine.StringField() )

	date_joined = mongoengine.DateTimeField(default=datetime.now())
	last_visited = mongoengine.DateTimeField(default=datetime.now())

	#empty array structure 
	friends = mongoengine.ListField()

#user_form = model_form(User)

#All classes info goes here
#Creating a new user, from example goes in the app.py

#class User(Document):
    #email = StringField(required=True)
    #first_name = StringField(max_length=50)
    #last_name = StringField(max_length=50)


    