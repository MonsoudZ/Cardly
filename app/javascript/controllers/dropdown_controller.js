import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.isOpen = false
    // Close dropdown when clicking outside
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this)
    document.addEventListener("click", this.closeOnClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnClickOutside)
  }

  toggle(event) {
    event.stopPropagation()
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.menuTarget.classList.remove('hidden', 'opacity-0', 'scale-95')
    this.menuTarget.classList.add('opacity-100', 'scale-100')
    this.isOpen = true
  }

  close() {
    this.menuTarget.classList.add('opacity-0', 'scale-95')
    this.menuTarget.classList.remove('opacity-100', 'scale-100')

    setTimeout(() => {
      if (!this.isOpen) {
        this.menuTarget.classList.add('hidden')
      }
    }, 100)

    this.isOpen = false
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target) && this.isOpen) {
      this.close()
    }
  }
}
