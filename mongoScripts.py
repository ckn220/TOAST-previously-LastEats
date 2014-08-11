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

def addDeleted():
    for idea in models.Idea.objects(complete = 1):
        idea.deleted = 1
        idea.save()
    for idea in models.Idea.objects(complete = 1):
        idea.deleted = 0
        idea.save()

def addFriends(appId, secret):
    for user in models.User.objects():
        
        url = 'https://graph.facebook.com/oauth/access_token?client_id='+ str(appId) +'&client_secret='+ str(secret) +'&grant_type=client_credentials'
        response = urllib2.urlopen(url)
        a = response.geturl()
        pass
        
        f = graph.get_connections(user.userid, connection_name = 'friends?fields=name,picture')
        
        all_friends = []
        for id in f['data']:
            all_friends.append({'id': id['id'], 'name': id['name'], 'picture': id['picture']['data']['url']})
        
        c = models.UserFriends(userid = user.userid, all_friends = all_friends)
        c.save()


def addEmail(appId, secret):
#     for user in models.User.objects():
#         if not hasattr(user, 'email') or user.email == None:
#             graph = facebook.GraphAPI(str(appId) + '|' + str(secret))
#             me = graph.get_objects([user.userid])
#             
#             try:
#                 if user.userid in me and 'email' in me[user.userid]:
#                     print me[user.userid]['email']
#                     user.email = me[user.userid]['email']
#                     user.save()
#             except:
#                 pass
    
    f = open('emails.csv')
    for row in f: 
        data = row.replace('\n','').split(',')
        names = data[0].split(' ',1)
        
        user = models.User.objects(user_name = names[0], user_last_name = names[1]).first()
        
        if not user:
            print 'NO USER BY NAME ' + str(names)
            
        else:
            if not hasattr(user, 'email') or user.email == None:
                print 'New Email'
                user.email = data[1]
                user.save()
            else:
                print 'Already has email ' + str(user.email)
                print 'New Data = ' +str(data)
        print user
        
        
tagDict = ['Great for:','Vibe:','Attire:','Perks:','Price:','Diet:','Type:','\n']
def find_between( s, first, last ):
    try:
        start = s.index( first ) + len( first )
        end = s.index( last, start )
        return s[start:end]
    except ValueError as e:
        print e
        return ""
def addTags():
    f = open('tags.csv')
    for row in f:
        data = row.split('"')
        if len(data) == 3:
            id = data[2].replace(',http://beta.lasteats.com/last_eat_entry/','').replace('\n','')
            print id
            
            for i in range(len(tagDict)-1):
                print tagDict[i]
                if tagDict[i+1] in data[1] +'\n':
                    text = find_between(data[1] + '\n',tagDict[i],tagDict[i+1]).lstrip().rstrip().split(',')
                else:
                    text = find_between(data[1] + '\n',tagDict[i],tagDict[i+2]).lstrip().rstrip().split(',')
                
                print text
                for item in text:
                    if id == '53cdbbe1a40335000270686a':
                        pass
                    if item != '' and not models.Tag.objects(ideaid = id, type = tagDict[i].replace(':',''), text = item.lstrip().rstrip()).first():
                        
                        tag = models.Tag(ideaid = id, type = tagDict[i].replace(':',''), text = item.lstrip().rstrip())
                        tag.save()
                        pass           
            print ''
        
        
def getFullTagList():
    tagComp = {}
    for row in models.Tag.objects():
        if row.type not in tagComp:
            tagComp[row.type] = set([])
            
        tagComp[row.type].add(row.text)
        
    print tagComp
        
        
        
        

