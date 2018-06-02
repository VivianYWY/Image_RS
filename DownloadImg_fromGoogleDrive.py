# -*- coding: utf-8 -*-
"""
Created on Mon Feb 12 21:01:19 2018

@author: moonl
"""
from google_drive_downloader import GoogleDriveDownloader as gdd

gdd.download_file_from_google_drive(file_id='https://drive.google.com/file/d/1lFCAWIDmOT8j85mGEaEjx8fVJyVY1oVf/view?usp=sharing',
                                    dest_path='E:/s1.zip',
                                    unzip=False)
