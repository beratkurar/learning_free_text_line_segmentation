# -*- coding: utf-8 -*-
"""
Created on Tue Jan 23 10:46:02 2018

@author: B
"""

import os
import subprocess


p = subprocess.Popen(['java', '-jar',
                      'TranskribusBaseLineEvaluationScheme-0.1.3-jar-with-dependencies.jar',
                      'truths.lst','predicts.lst'], universal_newlines=True,
                     stdin=subprocess.PIPE, stdout=subprocess.PIPE,bufsize=1)
stdO,stdE = p.communicate()