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


from datetime import datetime
from pytz import timezone
def currentTime(zone):
	fmt = "%Y-%m-%d %H:%M:%S %Z%z"
	timezonelist = ['UTC','US/Pacific','Europe/Berlin']
	now_time = datetime.now(timezone(zone))
	return now_time


class Tag(Document):
	
	ideaid = mongoengine.fields.ObjectIdField()
	type = mongoengine.StringField()
	text = mongoengine.StringField()
	

class Comment(Document):
	
	userid = mongoengine.StringField()
	ideaid = mongoengine.StringField()
	comment_string = mongoengine.StringField(max_length=140)
	
	seen = mongoengine.IntField()
	
	timestamp = mongoengine.DateTimeField(default=datetime.now())
	

class Idea(Document):
	userid = mongoengine.StringField()
	
	restaurant = mongoengine.fields.ObjectIdField(required=True)
	
	complete = mongoengine.IntField(required=True, default=0)
	deleted = mongoengine.IntField(required=True, default=0)
	
# 	googleId = mongoengine.StringField()
# 	title = mongoengine.StringField(required=True)
# 	full_city = mongoengine.StringField()
# 	restaurant_name = mongoengine.StringField(required=True)
# 	point = mongoengine.PointField()#required=True)
# 	cost = mongoengine.IntField()
# 	filenames = mongoengine.ListField()
# 	phone = mongoengine.StringField()
# 	hours = mongoengine.ListField()
# 	address = mongoengine.StringField()
# 	types = mongoengine.ListField()
# 	website = mongoengine.StringField()
#	instagram_id = mongoengine.StringField()
	
	instagram_id = mongoengine.StringField()
	
	tag = mongoengine.StringField()
	instagram_tags = mongoengine.ListField(default=[])
	
	likes = mongoengine.ListField(default=[])
	like_count = mongoengine.IntField(default=0)
	
	idea = mongoengine.StringField(verbose_name="What makes it great?")
	order = mongoengine.StringField(verbose_name="What would you order?")
	
	slug = mongoengine.StringField()
	
	filename = mongoengine.fields.DictField()
	
	request_id = mongoengine.StringField()
	seen = mongoengine.IntField(default=0)
	
	# Timestamp will record the date and time idea was created.
	timestamp = mongoengine.DateTimeField(default = datetime.now(), required=True)
	
	hot = mongoengine.IntField()
	
	def get_res(self):
		return Restaurant.objects(id = self.restaurant).first()
	
	def get_tags(self):
		tags = {}
		for row in Tag.objects(ideaid = self.get_res().id):
			if row.type not in tags:
				tags[row.type] = []
			tags[row.type].append(row)
		
		for row in Tag.objects(ideaid = self.id):
			if row.type not in tags:
				tags[row.type] = []
			tags[row.type].append(row)
		
		return tags
	
class Restaurant(Document):
	googleId = mongoengine.StringField()
	
	city = mongoengine.StringField(default = '')
	full_city = mongoengine.StringField(default = '')
	
	name = mongoengine.StringField(required=True)
	
	latitude = mongoengine.StringField()
	longitude = mongoengine.StringField()
	point = mongoengine.PointField()#required=True)
	cost = mongoengine.IntField()
	
	filenames = mongoengine.ListField()
	instagram_id = mongoengine.StringField()
	
	phone = mongoengine.StringField()
	hours = mongoengine.ListField()
	address = mongoengine.StringField()
	
	types = mongoengine.ListField()
	website = mongoengine.StringField()
	
	
	def open_now(self):
		now_time = currentTime('EST')
		
		day = int(now_time.strftime('%w'))
		hour = int(now_time.strftime('%H%M'))

		if len(self.hours) > day:
			try:
				open = int(self.hours[day]['open']['time'])
				close = int(self.hours[day]['close']['time'])
				
				if open < close and hour > open and hour < close:
					return True
				elif open > close and (hour > open or hour < close):
					return True
				
			except Exception as e:
				print e
				
		return False
	

class Friend(mongoengine.EmbeddedDocument):
	#you have to push things into the array. Google how
	#with mongoengine's EmbeddedDocument

 	friend_id = mongoengine.IntField()
 	friend_name = mongoengine.StringField()


class User(Document):

	userid = mongoengine.StringField()
	user_name = mongoengine.StringField()
	user_last_name = mongoengine.StringField()
	
	email = mongoengine.StringField()
	picture = mongoengine.StringField()
	instagram_id = mongoengine.StringField()
	
	saves = mongoengine.ListField(default=[])
	
	notify_count = mongoengine.IntField(default = 0)
	
	#This works with storing the data as a string, but we want it in json in array
	#user_friends = mongoengine.ListField()
	
	#need to play with this for structuring the data into an array - the formating, it doesn't like ListField
	# user_friends = mongoengine.ListField( mongoengine.StringField() )

	date_joined = mongoengine.DateTimeField(default=datetime.now())
	last_visited = mongoengine.DateTimeField(default=datetime.now())
	picture_update = mongoengine.DateTimeField(default=datetime.now())

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

