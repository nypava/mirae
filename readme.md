## Mirae

Simple timer/stopwatch written in zig and raylib

https://github.com/user-attachments/assets/391e2372-d17e-43bc-9d3d-9f4d89ceed5f

### Build
```sh
zig build 
```
### Build and run
```sh
zig build run
```

### Install
```sh
zig build --prefix <location>
```
location:  location where the binary intend to be installed (for example ~/.local or /usr with sudo privilage)


### Usage
```
Usage: 
 mirae [time] [unit] [options]

Time formats
 mirae HH:MM:SS          set timer using full format
 mirae HH:MM h           set timer in hour and minute
 mirae MM:SS [m]         set timer in minute and second
 mirae <value> [s|m|h]   set timer with unit (second, minute, hour) 

Stopwatch Mode
 mirae                   if no <time> is provided, mirae runs as stop watch mode

Options
 -a, --alarm     play alarm sound when time is up 
 -w, --warning   color change to blinking on finale time
 -h, --help      Show this help message
```

**Controls** 

`r` -- restart \
`w` -- show warning \
`<space>` or `p` -- pause \
`+` and `-` -- scale up and scale down 




