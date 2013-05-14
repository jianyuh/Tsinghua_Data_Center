import web

db = web.database(dbn='mysql', db='webpygui', user='root', pw='root')

def gethost_posts():
    return db.select('nodeinfo', order='id DESC')

def gethost_post(id):
    try:
        return db.select('nodeinfo', where='id=$id', vars=locals())[0]
    except IndexError:
        return None

def newhost_post(hostname, macaddr, ipaddr):
    db.insert('nodeinfo',hostname=hostname, macaddr=macaddr, ipaddr=ipaddr )

def delhost_post(id):
    db.delete('nodeinfo',where='id=$id', vars=locals())

def updatehost_post(id, hostname, macaddr, ipaddr):
    db.update('nodeinfo',where='id=$id', vars=locals(), hostname=hostname, macaddr=macaddr, ipaddr=ipaddr)

def getmacofhost(hostname):
    try:
        return db.select("nodeinfo", what='macaddr', where="hostname=$hostname", vars=locals())[0]
    except IndexError:
        return None


def getimage_posts():
    return db.select('imageinfo', order='id DESC')

def getimage_post(id):
    try:
        return db.select('imageinfo', where='id=$id', vars=locals())[0]
    except IndexError:
        return None

def newimage_post(imagename, imagelocation):
    db.insert('imageinfo',imagename=imagename, imagelocation=imagelocation)

def delimage_post(id):
    db.delete('imageinfo',where='id=$id', vars=locals())

def updateimage_post(id, imagename, imagelocation):
    db.update('imageinfo',where='id=$id', vars=locals(), imagename=imagename, imagelocation=imagelocation)

def getimagelocation(imagename):
    try:
        return db.select("imageinfo",what='imagelocation',where='imagename=$imagename', vars=locals())[0]
    except IndexError:
        return None
