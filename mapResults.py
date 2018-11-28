## Loading data in python

import pandas as pd

mydata = pd.read_csv('instances2018/C1-3-12.txt',sep='\t')

## Plotting all points on the map


import folium
from IPython.display import HTML, display

m = folium.Map(location=[47.22, -1.555], zoom_start=12)

for i in range(0,len(mydata)):
    #myicon=folium.Icon(icon='box',prefix='fa',color='blue')
    myicon= folium.Icon(color='lightgreen',icon='cube',prefix='fa')
    if mydata.iloc[i]['VERTEX_TYPE']=="D":
        myicon=folium.Icon(color='red',icon='truck',prefix='fa')
    if mydata.iloc[i]['VERTEX_TYPE']=="P":
        myicon=folium.Icon(color='darkblue',icon='sign-out', prefix='fa') 
            #myicon=folium.Icon(icon='fa-cafe',prefix='map-icon')
    if mydata.iloc[i]['VERTEX_TYPE']=="L":
        myicon= folium.Icon(color='darkgreen',icon='cubes',prefix='fa')
    if mydata.iloc[i]['VERTEX_TYPE']=="LS":
        myicon= folium.Icon(color='green',icon='cubes',prefix='fa')
    popuptxt = str(mydata.iloc[i]['CUSTNO']) + '\t' + \
        str(mydata.iloc[i]['DEMAND']) +  '\t' + \
        mydata.iloc[i]['VERTEX_TYPE'] +  '\t' + \
        str(mydata.iloc[i]['LATITUDE']) +  '\t' + \
        str(mydata.iloc[i]['LONGITUDE']) +  '\t' + \
        str(mydata.iloc[i]['TW_OPENING'])
    folium.Marker(location=[mydata.iloc[i]['LATITUDE'], mydata.iloc[i]['LONGITUDE']], icon=myicon,  popup=popuptxt).add_to(m)


#Getting our trucks from the files :
smallTruck = []
bigTruck = []
with open("smallTruck.res", 'r') as truckFile:
    for line in truckFile:
        smallTruck.append(line.split())
with open("bigTruck.res", 'r') as truckFile:
    for line in truckFile:
        bigTruck.append(line.split())

smallTruckPoints = []
bigTruckPoints = []

for i in range(0, len(smallTruck)):
    for j in range(0, len(smallTruck)):
        smallTruckPoints = []
        bigTruckPoints = []
        if smallTruck[i][j] == '1':
            if i==len(mydata):
                smallTruckPoints.append((mydata.iloc[0].LATITUDE, mydata.iloc[0].LONGITUDE))
                smallTruckPoints.append((mydata.iloc[j].LATITUDE, mydata.iloc[j].LONGITUDE))
                print("adding small truck line between customers " + str(mydata.iloc[j].CUSTNO) + " and depot")
            elif j==len(mydata):
                print("adding small truck line between customers " + str(mydata.iloc[i].CUSTNO) + " and depot")
                smallTruckPoints.append((mydata.iloc[0].LATITUDE, mydata.iloc[0].LONGITUDE))
                smallTruckPoints.append((mydata.iloc[i].LATITUDE, mydata.iloc[i].LONGITUDE))
            else :    
                print("adding small truck line between customers " + str(mydata.iloc[i].CUSTNO) + " and " + str(mydata.iloc[j].CUSTNO))
                smallTruckPoints.append((mydata.iloc[i].LATITUDE, mydata.iloc[i].LONGITUDE))
                smallTruckPoints.append((mydata.iloc[j].LATITUDE, mydata.iloc[j].LONGITUDE))
            folium.PolyLine(smallTruckPoints,color="blue", weight=4, opacity=0.8).add_to(m)
                
        if bigTruck[i][j] == '1':
            if i==len(mydata):
                bigTruckPoints.append((mydata.iloc[0].LATITUDE, mydata.iloc[0].LONGITUDE))
                bigTruckPoints.append((mydata.iloc[j].LATITUDE, mydata.iloc[j].LONGITUDE))
                print("adding big truck line between customers " + str(mydata.iloc[j].CUSTNO) + " and depot")
            elif j==len(mydata):
                print("adding big truck line between customers " + str(mydata.iloc[i].CUSTNO) + " and depot")
                bigTruckPoints.append((mydata.iloc[0].LATITUDE, mydata.iloc[0].LONGITUDE))
                bigTruckPoints.append((mydata.iloc[i].LATITUDE, mydata.iloc[i].LONGITUDE))
            else :    
                print("adding big truck line between customers " + str(mydata.iloc[i].CUSTNO) + " and " + str(mydata.iloc[j].CUSTNO))
                bigTruckPoints.append((mydata.iloc[i].LATITUDE, mydata.iloc[i].LONGITUDE))
                bigTruckPoints.append((mydata.iloc[j].LATITUDE, mydata.iloc[j].LONGITUDE))
            folium.PolyLine(bigTruckPoints,color="red", weight=2, opacity=0.8).add_to(m)

m.save("resultMap.html")
