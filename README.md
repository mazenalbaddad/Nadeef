<img 
  src="https://github.com/user-attachments/assets/e603c5ca-0683-4005-96d4-e5737d43d06e"
  width="100%"
/>

# Nadeef

## To start using Nadeef:

### Setup

1- clone the package

2- change directory to the package 

3- build the package with release configuration
```bash
swift build --configuration release
```
4- copy the executable to the local binary directory
```bash
cp -f .build/release/nadeef /usr/local/bin
```
### Usage

Change directory into your project and run
```bash
Nadeef swift
```
#### Or

You can pass a relative path argument 
```bash
Nadeef swift Desktop/your-project
```
#### Also

You can specifying the roots object with the —roots option
```bash
Nadeef swift Desktop/your-project -roots AppDelegate
```
