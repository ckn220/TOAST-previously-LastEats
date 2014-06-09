import models


def convertLocation():
    
    for idea in models.Idea.objects(complete = 1):
        
        idea.point = [float(idea.longitude), float(idea.latitude)]
        idea.save()