Coming Soon
====================
+ Sample page on a cluster
+ Multiple rooms
+ Julia syntax parser

Installation
====================
This application requires Redis, NodeJS, Etherpad-lite, Socketstream and Julia. Please install them before proceeding.

### Redis Installation
Please follow the instruction at http://redis.io/download.

### NodeJS Installation
Please follow the instruction at http://nodejs.org/.

### Etherpad-lite Installation
Please follow the instruction at http://github.com/Pita/etherpad-lite.

### Socketstream Installation
Please follow the instruction at http://github.com/socketstream/socketstream or:
    
    npm install -g socketstream

### Julia Installation
Please follow the instruction at https://github.com/JuliaLang/julia

### Application Installation

To install:

    git clone git://github.com/Wisdom/juliaSocial.git
    cd juliaSocial
    npm install node-uuid

### Application Configuration
The configuration file is inside config/app.coffee. Please point julia to your julia binary and etherpad to your etherpad host.

### Running the application

First, start redis server:

    redis-server

Second, inside the juliaSocial folder run:

    socketstream start

If everything goes well, your application should be running. Visit http://localhost:3000 to see the application in action.