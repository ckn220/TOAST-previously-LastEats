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


class Comment(mongoengine.EmbeddedDocument):
	name = StringField()
	comment = StringField()
	timestamp = DateTimeField(default=datetime.now())
	

class Idea(Document):
	#joining the idea with the user when yo
	userid = mongoengine.IntField()
	#added mongoengine prefix to all fields for photo
	creator = mongoengine.StringField(max_length=120, required=True, verbose_name="First name")
	title = mongoengine.StringField(max_length=120, required=True)
	# restaurant_description = mongoengine.StringField(max_length=120, required=True)
	slug = mongoengine.StringField()
	idea = mongoengine.StringField(required=True, verbose_name="What is your idea?")
	restaurant_name = mongoengine.StringField(max_length=120, required=True)
	latitude = mongoengine.StringField(max_length=120, required=True)
	longitude = mongoengine.StringField(max_length=120, required=True)

	# Category is a list of Strings
	# categories = mongoengine.ListField( mongoengine.StringField(max_length=30))

	# Comments is a list of Document type 'Comments' defined above
	comments = mongoengine.ListField( mongoengine.EmbeddedDocumentField(Comment) )

	filename = mongoengine.StringField()

	# Timestamp will record the date and time idea was created.
	timestamp = mongoengine.DateTimeField(default=datetime.now())

photo_form = model_form(Idea)


#new for photo upload
class photo_upload_form(photo_form):

    fileupload = FileField('Upload an image file', validators=[])


class Friend(mongoengine.EmbeddedDocument):
	#you have to push things into the array. Google how
	#with mongoengine's EmbeddedDocument

 	friend_id = mongoengine.IntField()
 	friend_name = mongoengine.StringField()


class User(Document):

	userid = mongoengine.StringField()
	user_name = mongoengine.StringField()
	user_last_name = mongoengine.StringField()

	#This works with storing the data as a string, but we want it in json in array
	user_friends = mongoengine.StringField()
	
	#need to play with this for structuring the data into an array - the formating, it doesn't like ListField
	# user_friends = mongoengine.ListField( mongoengine.StringField() )

	date_joined = mongoengine.DateTimeField(default=datetime.now())
	last_visited = mongoengine.DateTimeField(default=datetime.now())

	#empty array structure 
	friends = mongoengine.ListField( mongoengine.EmbeddedDocumentField(Friend) )

user_form = model_form(User)

#All classes info goes here
#Creating a new user, from example goes in the app.py

#class User(Document):
    #email = StringField(required=True)
    #first_name = StringField(max_length=50)
    #last_name = StringField(max_length=50)


    