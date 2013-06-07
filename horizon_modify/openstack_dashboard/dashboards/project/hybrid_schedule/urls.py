# vim: tabstop=4 shiftwidth=4 softtabstop=4

# Copyright 2012 United States Government as represented by the
# Administrator of the National Aeronautics and Space Administration.
# All Rights Reserved.
#
# Copyright 2013 NTT MCL, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.


from django.conf.urls.defaults import url, patterns

#from .views import (NetworkTopology, JSONView)
#from django.views.generic.simple import redirect_to
#from django.views.generic import RedirectView
from django.http import HttpResponseRedirect
from django.core.urlresolvers import reverse

urlpatterns = patterns('',
    #'openstack_dashboard.dashboards.project.network_topology.views',
    #(r'^$', redirect_to, {'url':'/test/'}),
    #(r'^/$', RedirectView.as_view(url='/test/')),
    #url(r'^json$', JSONView.as_view(), name='json'),
    #myurl = reverse("www.google.com")
    #myurl = "http://www.google.com"
    url(r'^$', lambda x: HttpResponseRedirect('http://10.10.0.200:8080/hybridschedule'), name='index'),
)
