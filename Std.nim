import std/tables, macros
import lispobject
import Strings
import Math
import SysIo

const
  Stdlib* = toTable {
    "Strings": Strings.Module,
    "Math"   : Math.Module,
    "SysIo"  : SysIo.Module
  }

    
      
  
  
