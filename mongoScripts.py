import models
import urllib2

import facebook

def fixUsers():
    for user in models.User.objects():
        c = models.UserFriends(userid = user.userid, all_friends = user.all_friends)
        c.save()
        user.all_friends = None
        user.save()

def addSeen():
    for c in models.Comment.objects():
        c.seen = 0
        c.save()

def convertLocation():
    
    for idea in models.Idea.objects(complete = 1):
        
        idea.point = [float(idea.longitude), float(idea.latitude)]
        idea.save()
        
def addFriends(appId, secret):
    for user in models.User.objects():
        
#         url = 'https://graph.facebook.com/oauth/access_token?client_id='+ str(appId) +'&client_secret='+ str(secret) +'&grant_type=client_credentials'
#         response = urllib2.urlopen(url)
#         a = response.geturl()
#         pass
    
        graph = facebook.GraphAPI(str(appId) + '|' + str(secret))
        f = graph.get_connections(user.userid, connection_name = 'friends?fields=name,picture')
        
        all_friends = []
        for id in f['data']:
            all_friends.append({'id': id['id'], 'name': id['name'], 'picture': id['picture']['data']['url']})
        
        user.all_friends = all_friends
        user.save()
    