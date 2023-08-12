
This project is  creating a decentralized random lottery 

We are going to be using chain link  vrf2 to get  a random number(https://docs.chain.link/vrf/v2/subscription/examples/get-a-random-number
), and then we are going to use chainlink keepers to trigger the process to automatically have one of those winners get picked whenever the time interval is up. Once the keepers kick it off, they will pick a winner, our decentralized lottery will say the most previous winner is so and so and they will get all the money from this lottery.



// Requirements
//install hardhat 
npm install --dev hardhat
npx hardhat    //choose empty project
//install dependencies
npm 




Create a Subscription ID using your wallet address. The Subscription ID will be used in your contract when requesting a random value.
https://docs.chain.link/vrf/v2/subscription/examples/get-a-random-number
