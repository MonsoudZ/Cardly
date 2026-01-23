import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dismissible"
export default class extends Controller {
  dismiss() {
    this.element.classList.add('opacity-0', 'transform', 'scale-95')
    this.element.style.transition = 'opacity 150ms ease-out, transform 150ms ease-out'

    setTimeout(() => {
      this.element.remove()
    }, 150)
  }
}
