import web
import model
import os
import sys
import logging
import re


logger=logging.getLogger('shell')
logger.setLevel(logging.DEBUG)
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
formatter = logging.Formatter('[%(asctime)s] - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)


urls = (
    '/','Index',
    '/viewhost/(\d+)','Viewhost',
    '/newhost','Newhost',
    '/deletehost/(\d+)','Delhost',
    '/edithost/(\d+)','Edithost',
    '/viewimage/(\d+)','Viewimage',
    '/newimage','Newimage',
    '/deleteimage/(\d+)','Delimage',
    '/editimage/(\d+)','Editimage',
    '/reboot/(\d+)','Reboot',
    '/migration/(\d+)','Migration',
)

#render = web.template.render('templates', base='base')
render = web.template.render('templates')

class Index:   
    
    hostposts = model.gethost_posts()
    imageposts = model.getimage_posts()
    #hostonlyposts = model.gethostonly_posts()
    #print hostonlyposts
    hostlist = []
    for post in hostposts:
        hostlist.append(post.hostname)

    imagelist = []

    for post in imageposts:
        imagelist.append(post.imagename)

    form = web.form.Form(
        #hostposts = model.gethost_posts()
        web.form.Dropdown(name='host', args=hostlist),
        web.form.Dropdown(name='image', args=imagelist),
        web.form.Button('Set'),
        #web.form.Button('Migration'),
        #web.form.Button('Reboot&&Change OS'),
    ) 

#    form2 = web.form.Form(
#        web.form.Dropdown(name='host', args=hostlist),
#        web.form.Button('Migration'),
#    ) 

    def GET(self):
        hostposts = model.gethost_posts()
        imageposts = model.getimage_posts()

        form = self.form()
        #form2 = self.form2()
        #form = web.form.Form()
        return render.index(hostposts, imageposts, form)

    def POST(self):
	hostposts = model.gethost_posts()
	imageposts = model.getimage_posts()

        form = self.form()
        #form2 = self.form()
 
        if not form.validates():
            return render.index(hostposts, imageposts, form)
        #model.newhost_post(form.d.hostname, form.d.macaddr, form.d.ipaddr)
        #os.action!!!!!!!!!!!!!!
        print "SH action!"

        hostmac = model.getmacofhost(form.d.host).macaddr
        #print hostmac
        imagelocation = model.getimagelocation(form.d.image).imagelocation
        #print imagelocation
        #os.shell
        cmd = "expect -f et.sh "+hostmac+" "+imagelocation
        
        logger.info(cmd)
        print os.popen(cmd).read().strip()
        

        raise web.seeother('/')


class Viewhost:
    def GET(self,id):
        post = model.gethost_post(int(id))
        return render.viewhost(post)

vhostname = web.form.regexp(r"^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$",'must be a valid hostname')
vmacaddr = web.form.regexp(r"([0-9a-f]{2}:){5}[0-9a-f]{2}","must be a mac address")
vipaddr = web.form.regexp(r"^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$","must be an IP address")



class Newhost:
    form = web.form.Form(
        web.form.Textbox('hostname',vhostname,
                         size=30,
                         description="Hostname:"),
        web.form.Textbox('macaddr',vmacaddr,
                          size=30,
                          description="MAC address"),
        web.form.Textbox('ipaddr',vipaddr,
                         size=30,
                         description="IP address:"),

        #hostposts = model.gethost_posts()
        #web.form.Dropdown(name='foo', args=['a','b','c'], value='b'),
        web.form.Button('Edit'),
    ) 

    def GET(self):
        print "new part"
        form = self.form()
        return render.newhost(form)

    def POST(self):
        form = self.form()
        if not form.validates():
            return render.newhost(form)
        print "validated, but not posted"
        model.newhost_post(form.d.hostname, form.d.macaddr, form.d.ipaddr)
        raise web.seeother('/')


class Delhost:
    def POST(self,id):
        model.delhost_post(int(id))
        raise web.seeother('/')
    
class Edithost:
    def GET(self,id):
        post = model.gethost_post(int(id))
        form = Newhost.form()
        form.fill(post)
        return render.edithost(post, form)

    def POST(self,id):
        form = Newhost.form()
        post = model.gethost_post(int(id))
        if not form.validates():
            return render.edithost(post, form)
        model.updatehost_post(int(id), form.d.hostname, form.d.macaddr, form.d.ipaddr)
        raise web.seeother('/')


class Viewimage:
    def GET(self,id):
        post = model.getimage_post(int(id))
        return render.viewimage(post)

vimagename = web.form.regexp(r".{1,20}$",'must be between 1 and 20 characters')
vimagelocation = web.form.regexp(r"(\/.*?)+","must be a path")


class Newimage:
    form = web.form.Form(
        web.form.Textbox('imagename',vimagename,
                         size=30,
                         description="Image Name"),
        web.form.Textbox('imagelocation',vimagelocation,
                          size=30,
                          description="Image Location"),
        web.form.Button('Edit'),
    ) 

    def GET(self):
        print "new part"
        form = self.form()
        return render.newimage(form)

    def POST(self):
        form = self.form()
        if not form.validates():
            return render.newimage(form) 
        print "validated, but not posted"
        model.newimage_post(form.d.imagename, form.d.imagelocation)
        raise web.seeother('/')


class Delimage:
    def POST(self,id):
        model.delimage_post(int(id))
        raise web.seeother('/')
    
class Editimage:
    def GET(self,id):
        post = model.getimage_post(int(id))
        form = Newimage.form()
        form.fill(post)
        return render.editimage(post, form)

    def POST(self,id):
        form = Newimage.form()
        post = model.getimage_post(int(id))
        if not form.validates():
            return render.editimage(post, form)
        model.updateimage_post(int(id), form.d.imagename, form.d.imagelocation)
        raise web.seeother('/')


class Reboot:
    def GET(self,id):
        post = model.gethost_post(int(id))
        #os.shell
        cmd = "expect -f et3.sh "+post.ipaddr
        logger.info(cmd)
        print os.popen(cmd).read().strip()
        raise web.seeother('/')

class Migration:
    def GET(self,id):
        post = model.gethost_post(int(id))
        #os.shell

        if post.hostname=="compute":
            fromhost="compute"
            tohost="compute2"
        else:
            fromhost="compute2"
            tohost="compute"

        cmd="nova list --all-tenants | awk {'print $2'}"
        str=os.popen(cmd).read().strip()
        instanceIDgroup=re.split('\n',str)

        migrationInstaceGroup=[]

        for instanceID in instanceIDgroup:
            if instanceID=="":
                continue
            if instanceID=="ID":
                continue
            cmd="nova show "+instanceID+"|grep OS-EXT-SRV-ATTR:host| awk {'print $4'}"
            if os.popen(cmd).read().strip()==fromhost:
                migrationInstaceGroup.append(instanceID)


        for instanceID in migrationInstaceGroup:
            cmd="nova live-migration "+instanceID+" "+tohost
            print "migration result:",os.popen(cmd).read().strip()

        print "finished"
        raise web.seeother('/')


app = web.application(urls, globals())

if __name__ == '__main__':
    app.run()






