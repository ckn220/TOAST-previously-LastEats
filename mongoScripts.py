import models
import urllib2

import facebook

def runAll(appId, secret):
#     addFriends(appId, secret)
#     addSeen()
#     convertFilename()
#     convertTitle()
#     convertLocation()
    pass

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


def convertFilename():
    for idea in models.Idea.objects(complete = 1):
        if not isinstance(idea.filename, dict):
            idea.filename = {'url': idea.filename}
            
        for i in range(len(idea.filenames)):
            if not isinstance(idea.filenames[i], dict):
                idea.filenames[i] = {'url': idea.filenames[i]}
        idea.save()
        
def convertTitle():
    
    for idea in models.Idea.objects(complete = 1):
        if not idea.full_city:
            idea.full_city = idea.title
            idea.save()

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
        
        if not hasattr(user, 'email') or user.email == None:
            graph = facebook.GraphAPI(str(appId) + '|' + str(secret))
            me = graph.get_objects([user.userid])
            
            try:
                if user.userid in me and 'email' in me[user.userid]:
                    print me[user.userid]['email']
                    user.email = me[user.userid]['email']
                    user.save()
            except:
                pass
#         f = graph.get_connections(user.userid, connection_name = 'friends?fields=name,picture')
#         
#         all_friends = []
#         for id in f['data']:
#             all_friends.append({'id': id['id'], 'name': id['name'], 'picture': id['picture']['data']['url']})
#         
#         c = models.UserFriends(userid = user.userid, all_friends = all_friends)
#         c.save()



        
        
        
