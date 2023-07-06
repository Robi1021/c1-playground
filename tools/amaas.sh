#!/bin/bash

#upgrade Python to min. 3.8 
   sudo apt-get install -y python3.8 python3.8-dev python3.8-distutils python3.8-venv
   sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1
   
#2. Clone the VSAPI Repo:
   git clone https://github.com/trendmicro/cloudone-antimalware-python-sdk
   cd cloudone-antimalware-python-sdk
   python3 -m pip install cloudone-vsapi