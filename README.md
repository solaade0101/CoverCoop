SafeDrive is a blockchainbased gamified insurance protocol that rewards safe driving behavior with STX tokens and reduces premiums through verifiable driving data on the Stacks network.

 Overview

SafeDrive revolutionizes the insurance industry by leveraging smart contracts to:
 Track and reward safe driving behavior with STX token rewards
 Dynamically reduce insurance premiums based on verified driving data
 Gamify safe driving through scoring systems and achievement milestones
 Create transparent, verifiable records of driving history onchain

 Features

 1. Driver Registration
 Simple onetime registration process
 Initial driving score of 50/100
 Baseline premium calculation

 2. Trip Recording & Safety Tracking
 Record completed trips with distance, duration, and safety ratings (0100)
 Automatic validation of safety data
 Tripbytrip history stored onchain

 3. Reward Mechanism
 Claim rewards for each completed safe driving trip
 Reward amount calculated as: `(safety_rating × 100) ÷ 10`
 Cumulative rewards tracked per driver

 4. Dynamic Scoring System
 Driving score increases based on trip safety ratings
 Score capped at 100/100
 Score impacts premium calculations

 5. Premium Reduction
 Dynamic premium discounts based on total rewards:
   10% discount at 100+ rewards
   20% discount at 500+ rewards
   30% discount at 1000+ rewards
 Base premium: 10,000 units
 Adjusted premiums calculated in realtime

 Contract Functions

 Public Functions

 `registerdriver`
Register a new driver in the SafeDrive protocol.
 Returns: Success message or error

 `recorddrivingtrip (distance: uint) (duration: uint) (safetyrating: uint)`
Record a completed driving trip with safety metrics.
 Parameters:
   `distance`: Trip distance in miles/km
   `duration`: Trip duration in minutes
   `safetyrating`: Safety score (0100)
 Returns: Trip ID or error

 `claimtripreward (tripid: uint)`
Claim STX token rewards for a completed trip.
 Parameters:
   `tripid`: ID of the trip to claim rewards for
 Returns: Reward amount or error

 ReadOnly Functions

 `getdriverinfo (driver: principal)`
Retrieve complete driver profile including score, rewards, and premium discount.

 `gettriprecord (driver: principal) (tripid: uint)`
Retrieve detailed information about a specific trip.

 `getdrivingscore (driver: principal)`
Get the current driving score for a driver.

 `gettotalrewards (driver: principal)`
Get total STX rewards earned by a driver.

 `getpremiumdiscount (driver: principal)`
Get current premium discount percentage for a driver.

 `calculateadjustedpremium (driver: principal)`
Calculate the adjusted insurance premium based on current discount.

 `gettripscompleted (driver: principal)`
Get total number of trips completed by a driver.

 Usage Example

 1. Register as a Driver
clarity
(contractcall? .safedrv registerdriver)

🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines] for details.

 Development Setup
1. Install Clarinet
2. Clone the repository
3. Run `clarinet check` to validate contracts
4. Submit pull requests with comprehensive tests

 📄 License

This project is licensed under the MIT License  see the (LICENSE) file for details.

 🛠️ Support

 Documentation
 [Stacks Documentation](https://docs.stacks.co/)
 [Clarity Language Reference](https://docs.stacks.co/clarity/)

