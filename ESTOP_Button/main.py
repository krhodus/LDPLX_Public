"""
LDPLX - FPP ESTOP
v0.2
KEVIN@LDPLIGHTS.COM

Based on MQTT Example from
forum.micropython.org
"""
import network
import time

from secrets import secrets
from umqtt.simple import MQTTClient
from machine import Pin

#ESTOP PIN
ESTOP = Pin(14, Pin.IN, Pin.PULL_UP)
Door = Pin(17, Pin.IN, Pin.PULL_UP)
led = machine.Pin("LED", machine.Pin.OUT)

### Wireless Config ###
wifi_ssid = secrets['wifi_ssid']
wifi_password = secrets['wifi_password']
rp2.country('US')

wlan = network.WLAN(network.STA_IF)
wlan.active(True)
wlan.connect(wifi_ssid, wifi_password)
while wlan.isconnected() == False:
    print('Waiting for connection...')
    time.sleep(1)
    led.value(0)
print("Connected to WiFi")
status = wlan.ifconfig()
print('ip = ' + status[0])


### MQTT Topic Setup ###
broker = secrets['broker']
client_id = secrets['client_id']
sub_topic = secrets['subtopic']
HB_topic = secrets['HB_topic']
ESTOP_topic = secrets['ESTOP_topic']
Door_topic = secrets['Door_topic']
Master_Seq_topic = secrets['Master_Seq_topic']
Secondary_Seq_topic = secrets['Secondary_Seq_topics']

def sub_cb(topic, msg):
    #For Future Use to parse topics from server
  print((topic, msg))
  #if msg == "message":

def connect_and_subscribe():
  global client_id, mqtt_server, topic_sub
  client = MQTTClient(client_id, broker)
  client.set_callback(sub_cb)
  client.connect()
  client.subscribe(sub_topic)
  print('Connected to %s MQTT broker as client ID: %s, subscribed to %s topic' % (broker, client_id, sub_topic))
  return client

def restart_and_reconnect():
  print('Failed to connect to MQTT broker. Reconnecting...')
  time.sleep(10)
  machine.reset()

try:
  client = connect_and_subscribe()
except OSError as e:
  restart_and_reconnect()

### GPIO / Heatbeat Functions ###
def StartUpDoor():
    global Door_State
    if Door.value() == 0:
        print("Door Opened")
        Door_State = True
        door_msg = '{"Door":true}'
        print(Door_topic,"  ",door_msg)
        client.publish(Door_topic, door_msg,True,1)
    else:
        print("Door Closed")
        Door_State = False
        door_msg = '{"Door":false}'
        print(Door_topic,"  ",door_msg)
        client.publish(Door_topic, door_msg)   

def CheckDoor():
    global Door_State
    if Door.value() == 0:
        if Door_State != True:
            print("Door Opened")
            Door_State = True
            door_msg = '{"Door":true}'
            print(Door_topic,"  ",door_msg)
            client.publish(Door_topic, door_msg,True,1)
    else:
        if Door_State != False:
            print("Door Closed")
            Door_State = False
            door_msg = '{"Door":false}'
            print(Door_topic,"  ",door_msg)
            client.publish(Door_topic, door_msg)   

def StartUpESTOP():
    global ESTOP_State
    if ESTOP.value() == 0:
        print("ESTOP ACTIVED")
        ESTOP_State = True
        pub_msg = '{"ESTOP":true}'
        print(ESTOP_topic,"  ",pub_msg)
        client.publish(ESTOP_topic, pub_msg,True,1)
        client.publish(Master_Seq_topic, "")
        client.publish(Secondary_Seq_topic, "")
    else:
        print("ESTOP DEACTIVATED")
        ESTOP_State = False
        pub_msg = '{"ESTOP":false}'
        print(ESTOP_topic,"  ",pub_msg)
        client.publish(ESTOP_topic, pub_msg)   

def CheckESTOP():
    global ESTOP_State
    if ESTOP.value() == 0:
        if ESTOP_State != True:
            print("ESTOP ACTIVED")
            ESTOP_State = True
            pub_msg = '{"ESTOP":true}'
            print(ESTOP_topic,"  ",pub_msg)
            client.publish(ESTOP_topic, pub_msg,True,1)
            client.publish(Master_Seq_topic, "")
            client.publish(Secondary_Seq_topic, "")
    else:
        if ESTOP_State != False:
            print("ESTOP DEACTIVATED")
            ESTOP_State = False
            pub_msg = '{"ESTOP":false}'
            print(ESTOP_topic,"  ",pub_msg)
            client.publish(ESTOP_topic, pub_msg)

global HBCounter, Heartbeat
HBCounter= 0
HeartbeatCount = 1
hb_msg = '{{"Heartbeat":{0}}}'.format(str(HeartbeatCount))
print(hb_msg)
client.publish(HB_topic, hb_msg)

def Heartbeat():
    global HBCounter, HeartbeatCount
    if HBCounter < 60:
        HBCounter = HBCounter + 1
    else:
        HBCounter = 0
        HeartbeatCount = HeartbeatCount + 1
        hb_msg = '{{"Heartbeat":{0}}}'.format(str(HeartbeatCount))
        print(hb_msg)
        client.publish(HB_topic, hb_msg)

### Run Loop ###
led.value(1)
StartUpESTOP()
StartUpDoor()

while True:
    try:
        CheckESTOP()
        CheckDoor()
        Heartbeat()
        time.sleep(.5)
    except OSError as e:
        pass
        restart_and_reconnect()
