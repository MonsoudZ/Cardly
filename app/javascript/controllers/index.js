// Import and register all your controllers from the importmap under controllers/*

import { application } from "./application"

// This is a simple example controller
//import HelloController from "./hello_controller"
//application.register("hello", HelloController)

// Add more controllers as needed

// Import and register all your controllers from here
import DropdownController from "./dropdown_controller"
application.register("dropdown", DropdownController)
