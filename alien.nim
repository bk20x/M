

type
  Alien* = ref object of RootObj
    tname*: string


method describe*(a: Alien): string {.base.} = a.tname

