import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tabs"
export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { index: { type: Number, default: 0 } }

  connect() {
    this.showTab(this.indexValue)
  }

  select(event) {
    const index = this.tabTargets.indexOf(event.currentTarget)
    this.indexValue = index
    this.showTab(index)
  }

  showTab(index) {
    this.tabTargets.forEach((tab, i) => {
      if (i === index) {
        tab.classList.add('border-primary-500', 'text-primary-600')
        tab.classList.remove('border-transparent', 'text-neutral-500')
      } else {
        tab.classList.remove('border-primary-500', 'text-primary-600')
        tab.classList.add('border-transparent', 'text-neutral-500')
      }
    })

    this.panelTargets.forEach((panel, i) => {
      if (i === index) {
        panel.classList.remove('hidden')
        panel.classList.add('animate-fade-in')
      } else {
        panel.classList.add('hidden')
        panel.classList.remove('animate-fade-in')
      }
    })
  }
}
