const TARGET_URL = 'http://learn-asg-terramino-lb-1691914158.us-east-1.elb.amazonaws.com:8021/users';
/* const TARGET_URL = 'http://localhost:8021/users'; */

function simulateRequest() {
    fetch(TARGET_URL)
    .then(res => {
        console.log('Request successful');
    })
    .catch(err => {
        console.error('Request failed', err);
    })
}

function simulateRequests(numOfRequests) {
    for (let i = 0; i < numOfRequests; i++) {
        simulateRequest();
    }
}