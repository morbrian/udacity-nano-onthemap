# On The Map

This is my project submission for the Udacity Course *iOS Networking with Swift*, the 3rd course in the *iOS Developer Nanodegree*.

## Table of Contents

* [App Overview](#app-overview)
* [Login Screen Implementation](#login-screen-implementation)


## App Overview

The **On The Map** iOS App functional UI design is specified by Udacity. My implementation sticks very closely to the provided design, with the exception of the added *Account* tab which is an additional tab I chose to add.

This overview will describe the required baseline functionality of the app. The rest of the document will highlight specific areas of my implementation in the context of the baseline design. All screen captures will be from my implementation, and may differ slightly from the mockups provided by Udacity.

The general user workflow for the app is listed in the diagram below. The user is presented with a login screen and may login using either Facebook or a Udacity username password. After login, the user is taking to a map view displaying student study locations geographically. The user may choose to view a listing of the student data in a table view. Finally, the user may create a study location of their own by searching for a place name, and then associating a URL with the place entry.

![User Workflow Baseline](doc/img/User-Workflow-Baseline.png)

## Login Screen Implementation

In addition to the minimum baseline functionality, the login page supports logging in with Facebook using the ‘FBSDKLoginButton`.

Errors are reported as part of the UI design, rather than using a more intrusive alert popup.

![Login Screen Errors](doc/img/LoginScreen-Errors.png)


