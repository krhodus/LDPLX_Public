// LDPLXNet - Shelly Switch Rebooter

// Based on: Shelly Script example: Router Watchdog - Apache License v2

let CONFIG = {
  endpoints: [
    "http://10.0.60.12",
    "http://10.0.60.13",
    "http://mqtt.ldplxnet:18083/",
    
  ],
  //number of failures that trigger the reset
  numberOfFails: 5,
  //time in seconds after which the http request is considered failed
  httpTimeout: 20,
  //time in seconds for the relay to be off
  toggleTime: 5,
  //time in seconds to retry a "ping"
  pingTime: 60,
};

let endpointIdx = 0;
let failCounter = 0;
let pingTimer = null;

function pingEndpoints() {
  Shelly.call(
    "http.get",
    { url: CONFIG.endpoints[endpointIdx], timeout: CONFIG.httpTimeout },
    function (response, error_code, error_message) {
      //http timeout, magic number, not yet documented
      if (error_code === -114 || error_code === -104) {
        print(CONFIG.endpoints[endpointIdx])
        print(error_code)
        //print("Failed to fetch ", CONFIG.endpoints[endpointIdx]);
        failCounter++;
        print("Rotating through endpoints");
        endpointIdx++;
        endpointIdx = endpointIdx % CONFIG.endpoints.length;
      } else {
        //print(CONFIG.endpoints[endpointIdx])
        //print(error_code)
        //print("Ping Sucessful")
        failCounter = 0;
      }

      if (failCounter >= CONFIG.numberOfFails) {
        print("Too many fails, resetting...");
        failCounter = 0;
        Timer.clear(pingTimer);
        //set the output with toggling back
        Shelly.call(
          "Switch.Set",
          { id: 0, on: false, toggle_after: CONFIG.toggleTime },
          function () {}
        );
        return;
      }
    }
  );
}

print("Start watchdog timer");
pingTimer = Timer.set(CONFIG.pingTime * 1000, true, pingEndpoints);

Shelly.addStatusHandler(function (status) {
  //is the component a switch
  if(status.name !== "switch") return;
  //is it the one with id 0
  if(status.id !== 0) return;
  //does it have a delta.source property
  if(typeof status.delta.source === "undefined") return;
  //is the source a timer
  if(status.delta.source !== "timer") return;
  //is it turned on
  if(status.delta.output !== true) return;
  //start the loop to ping the endpoints again
  pingTimer = Timer.set(CONFIG.pingTime * 1000, true, pingEndpoints);
});
