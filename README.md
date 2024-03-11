# zmongo

## What is it

`zmongo` is a wrapper to [official mongo-c-driver](https://github.com/mongodb/mongo-c-driver.git) - client [MongoDB](https://www.mongodb.com/) library.

It is meant to be a temporary solution to use `mongodb` database for ziglang until we have a native ziglang driver for mongodb.

- Current `mongo-c-driver` version **v1.26.1**.
- Current zig version **0.12.0-dev.2711+f995c1b08**.

**This is work in progress**

## How to use

See `example` for detail how to setup.

`example` can be run as following:

- Run mongodb server in docker: `bash ./libmongoc/mongodb-server.sh`.

- Run the example in `example` folder: 

```bash
cd example
zig build run
```

