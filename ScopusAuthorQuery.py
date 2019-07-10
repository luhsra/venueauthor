# -*- coding: utf-8 -*-
# $Id: ScopusAuthorQuery.py 19013 2019-07-09 09:32:46Z hannig $
#
# Extracts the affiliation country for given author names using the Scopus Search API.
#
# Input is a CSV file, consisting of at least one column that contains the authors' first names,
# and one column that contains the authors' last names
#
# Results are written to STDOUT again as the original read-in CSV, plus a additional column "ScopusCountry",
# which denotes the affiliation country of a queried author.
# 

import csv
from collections import defaultdict
import requests
import json

import sys
reload(sys)
sys.setdefaultencoding('utf-8')

columns = defaultdict(list) # each value in each CSV column is appended to a list

#with open('StichprobeFrauen306.csv') as file:
with open('StichprobeMaenner372.csv') as file:
  file.read(3)  # consume BOM
  reader = csv.DictReader(file, delimiter=";") # read rows as dictionary format
  for row in reader:                           # read a row as {col1: val1, col2: val2,...}
    for (k,v) in row.items():                  # iterate over each column name and value 
      columns[k].append(v)                     # append value v in the appropriate list based on column name k


headers = { 'Content-Type': 'application/json; charset=UTF-8' }

params = (
    ('query', 'authlast(hannig) and authfirst(frank)'),
    ('apiKey', 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx')     # ENTER YOUR API KEY HERE
)

print("ID;Vorname;Nachname;Origin;Gender;FalseTrue;ScopusCountry")
# in our example, the CSV file has several columns but only the first name ("Vorname") and last name ("Nachname") columns are of interest
for i in range(len(columns['Vorname'])):
  csvID        = columns['ID'][i]         # 1st column, not required for search
  csvLastName  = columns['Nachname'][i]   # last name, required for search query
  csvFirstName = columns['Vorname'][i]    # first name, required for search query
  csvOrigin    = columns['Origin'][i]     # not required for search
  csvGender    = columns['Gender'][i]     # not required for search
  csvFalseTrue = columns['FalseTrue'][i]  # not required for search
  
  # form a Scopus query based on the first and last name of an author
  params = (('query', 'authlast(' + csvLastName + ') and authfirst(' + csvFirstName + ')'), params[1])
  response = requests.get('https://api.elsevier.com/content/search/author', headers=headers, params=params)
  #print response.headers
  json_response = response.json()
  json_data = json.loads(response.text)
  #print(json.dumps(json_response, indent=4, sort_keys=True))
  
  # select best (first, i.e., most recent) match, and fetch country of affiliation 
  csvOldColmns = csvID + ';' + csvFirstName + ';' + csvLastName + ';' + csvOrigin + ';'  + csvGender + ';' + csvFalseTrue + ';'
  if json_data['search-results']['entry'][0].has_key('affiliation-current') and json_data['search-results']['entry'][0]['affiliation-current'].has_key('affiliation-country') and json_data['search-results']['entry'][0]['affiliation-current']['affiliation-country']!=None:
    print csvOldColmns + json_data['search-results']['entry'][0]['affiliation-current']['affiliation-country']
  else:
    print csvOldColmns + "UNDEFINED"

