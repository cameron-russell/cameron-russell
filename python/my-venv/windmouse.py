import numpy as np
import pyautogui as pyautogui
import time
import random

sqrt3 = np.sqrt(3)
sqrt5 = np.sqrt(5)

def wind_mouse(start_x, start_y, dest_x, dest_y, G_0=9, W_0=3, M_0=15, D_0=12, move_mouse=lambda x,y: None):
    '''
    WindMouse algorithm. Calls the move_mouse kwarg with each new step.
    Released under the terms of the GPLv3 license.
    G_0 - magnitude of the gravitational fornce
    W_0 - magnitude of the wind force fluctuations
    M_0 - maximum step size (velocity clip threshold)
    D_0 - distance where wind behavior changes from random to damped
    '''
    current_x,current_y = start_x,start_y
    v_x = v_y = W_x = W_y = 0
    while (dist:=np.hypot(dest_x-start_x,dest_y-start_y)) >= 1:
        W_mag = min(W_0, dist)
        if dist >= D_0:
            W_x = W_x/sqrt3 + (2*np.random.random()-1)*W_mag/sqrt5
            W_y = W_y/sqrt3 + (2*np.random.random()-1)*W_mag/sqrt5
        else:
            W_x /= sqrt3
            W_y /= sqrt3
            if M_0 < 3:
                M_0 = np.random.random()*3 + 3
            else:
                M_0 /= sqrt5
        v_x += W_x + G_0*(dest_x-start_x)/dist
        v_y += W_y + G_0*(dest_y-start_y)/dist
        v_mag = np.hypot(v_x, v_y)
        if v_mag > M_0:
            v_clip = M_0/2 + np.random.random()*M_0/2
            v_x = (v_x/v_mag) * v_clip
            v_y = (v_y/v_mag) * v_clip
        start_x += v_x
        start_y += v_y
        move_x = int(np.round(start_x))
        move_y = int(np.round(start_y))
        if current_x != move_x or current_y != move_y:
            #This should wait for the mouse polling interval
            move_mouse(current_x:=move_x,current_y:=move_y)
    return current_x,current_y

def mylamda(x, y):
    pyautogui.moveTo(x, y)
    # x = random.randrange(2, 3)
    time.sleep(0.001)

red = (255, 0, 255)
# green = (0, 208, 0)

def findGreenOrRed():
    traps = []
    s = pyautogui.screenshot(region=(0,0,750,600))
    s.save("C:\\Users\\Cameron\\Desktop\\screenshot.png")
    x = 0
    y = 0
    while x < s.width:
        y = 0
        while y < s.height:
            pix = s.getpixel((x, y))
            if pix == red:
                print("found a pixel at x: " + str(x) + " y: " + str(y))
                newX = random.randint(-10,10)
                newY = random.randint(-10,10)
                traps.append((x + newX, y + newY))  # do something here
                x += 27
                y += 27
            y+=1
        x+=1
    return traps


pyautogui.PAUSE = 0



i = 0
while i < 10:
    t = findGreenOrRed()
    print(t)
    for location in t:
        curX, curY = pyautogui.position()
        pyautogui.moveTo(location[0],location[1])
        wind_mouse(curX, curY, curX+400, curY, W_0=7, move_mouse=lambda x,y: mylamda(x,y))
        pyautogui.click()
        time.sleep(8)

    time.sleep(2)
    i+=1