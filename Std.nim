import std/tables, macros
import lispobject
import Strings
import Math
import SysIo
import Tables
const
  Stdlib* = toTable {
    "Strings": Strings.Module,
    "Math"   : Math.Module,
    "SysIo"  : SysIo.Module,
    "Tables" : Tables.Module
  }

    
      
  
  
