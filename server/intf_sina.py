#!/usr/bin/env python
#
# Copyright 2007 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
import webapp2
from common.open import sina
import urllib
from common.utils import util
from google.appengine.runtime import DeadlineExceededError

class MainHandler(webapp2.RequestHandler):
    
    def get(self):
        pass

class OAuthHandler(webapp2.RequestHandler):
    
    def get(self):
        oauth = sina.OAuth()
        self.redirect(oauth.get_authorize_url())

class CallBackHandler(webapp2.RequestHandler):
    def get(self):
        code=self.request.get('code')
        self.response.write(code+'\n')
        oauth = sina.OAuth()
        req = {}
        req["account_type"] = "sina"
        req["account_name"] = ''
        req["access_token"] = ''
        req["expire_in"] = 0
        try:
            access_token = oauth.get_access_token(code)
            s = sina.Sina(access_token)
            req["account_name"] = s.api.account__get_uid()["uid"]
            req["access_token"] = access_token
            req["expire_in"] = s.get_info()["expire_in"]
        except:
            pass
        util.redirect_to_login(self, req)
        
app = webapp2.WSGIApplication([
    ('/intf/sina/', MainHandler), 
    ('/intf/sina/callback',CallBackHandler),
    ('/intf/sina/oauth', OAuthHandler)
], debug=True)