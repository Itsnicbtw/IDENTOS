#!/usr/bin/env python3
import pathlib
import subprocess
import unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
class HardwareTests(unittest.TestCase):
 def test_iso_builder_syntax(self):
  subprocess.run(["bash","-n",str(ROOT/"kernel/make-boot-iso.sh")],check=True)
 def test_config(self):
  text=(ROOT/"kernel/config/identium-hardware.fragment").read_text()
  for key in ("CONFIG_USB_STORAGE=y","CONFIG_SATA_AHCI=y","CONFIG_BLK_DEV_NVME=y","CONFIG_VT_CONSOLE=y"):
   self.assertIn(key,text)
 def test_reject_device_output(self):
  result=subprocess.run(["bash",str(ROOT/"kernel/make-boot-iso.sh"),"/tmp/k","/tmp/i","/dev/sda"],capture_output=True)
  self.assertNotEqual(result.returncode,0)
if __name__=="__main__": unittest.main()
