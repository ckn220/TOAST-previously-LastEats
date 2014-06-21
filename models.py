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
	
	seen = mongoengine.IntField(default=0)
	
	timestamp = mongoengine.DateTimeField(default=datetime.now())
	

class Idea(Document):
	userid = mongoengine.StringField()
	complete = mongoengine.IntField(required=True, default=0)
	
	title = mongoengine.StringField(required=True)
	full_city = mongoengine.StringField()
	restaurant_name = mongoengine.StringField(required=True)
	
	point = mongoengine.PointField(required=True)
	
	cost = mongoengine.IntField()
	
	likes = mongoengine.ListField(default=[])
	like_count = mongoengine.IntField(default=0)
	
	idea = mongoengine.StringField(verbose_name="What makes it great?")
	order = mongoengine.StringField(verbose_name="What would you order?")
	
	slug = mongoengine.StringField()
	instagram_id = mongoengine.StringField()
	
	filename = mongoengine.fields.DictField()
	filenames = mongoengine.ListField()
	
	request_id = mongoengine.StringField()
	seen = mongoengine.IntField(default=0)
	
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
	
	saves = mongoengine.ListField(default=[])
	
	notify_count = mongoengine.IntField(default = 0)
	
	#This works with storing the data as a string, but we want it in json in array
	#user_friends = mongoengine.ListField()
	
	#need to play with this for structuring the data into an array - the formating, it doesn't like ListField
	# user_friends = mongoengine.ListField( mongoengine.StringField() )

	date_joined = mongoengine.DateTimeField(default=datetime.now())
	last_visited = mongoengine.DateTimeField(default=datetime.now())

	#empty array structure 
	friends = mongoengine.ListField()

class UserFriends(Document):
	userid = mongoengine.StringField()
	all_friends = mongoengine.ListField()

class Request(Document):
	userid = mongoengine.StringField(required=True)
	friends = mongoengine.ListField()
	
	#How does friends seeing the request get recorded??
	
	title = mongoengine.StringField(required=True)
	full_city = mongoengine.StringField(required=True)

	point = mongoengine.PointField(required=True)

