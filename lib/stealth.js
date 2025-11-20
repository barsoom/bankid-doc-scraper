// Override navigator.webdriver
Object.defineProperty(navigator, 'webdriver', {
  get: () => undefined
});

// Override plugins to appear more realistic
Object.defineProperty(navigator, 'plugins', {
  get: () => [
    {
      0: {type: "application/x-google-chrome-pdf", suffixes: "pdf", description: "Portable Document Format"},
      description: "Portable Document Format",
      filename: "internal-pdf-viewer",
      length: 1,
      name: "Chrome PDF Plugin"
    },
    {
      0: {type: "application/pdf", suffixes: "pdf", description: "Portable Document Format"},
      description: "Portable Document Format",
      filename: "mhjfbmdgcfjbbpaeojofohoefgiehjai",
      length: 1,
      name: "Chrome PDF Viewer"
    },
    {
      0: {type: "application/x-nacl", suffixes: "", description: "Native Client Executable"},
      1: {type: "application/x-pnacl", suffixes: "", description: "Portable Native Client Executable"},
      description: "",
      filename: "internal-nacl-plugin",
      length: 2,
      name: "Native Client"
    }
  ]
});

// Override languages
Object.defineProperty(navigator, 'languages', {
  get: () => ['en-US', 'en', 'sv']
});

// Add chrome object
if (!window.chrome) {
  window.chrome = {
    runtime: {}
  };
}

// Override permissions
const originalQuery = window.navigator.permissions.query;
window.navigator.permissions.query = (parameters) => (
  parameters.name === 'notifications' ?
    Promise.resolve({ state: Notification.permission }) :
    originalQuery(parameters)
);

// Add realistic connection info
Object.defineProperty(navigator, 'connection', {
  get: () => ({
    downlink: 10,
    effectiveType: '4g',
    rtt: 50,
    saveData: false
  })
});

// Add deviceMemory
Object.defineProperty(navigator, 'deviceMemory', {
  get: () => 8
});

// Add hardwareConcurrency
Object.defineProperty(navigator, 'hardwareConcurrency', {
  get: () => 8
});

// Make toString functions appear normal
const toStringFix = (obj, name) => {
  const handler = {
    apply: function(target, ctx, args) {
      return name;
    }
  };
  obj.toString = new Proxy(obj.toString, handler);
};

toStringFix(navigator.permissions.query, 'function query() { [native code] }');
