import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['tab', 'panel']

  connect() {
    const active = this.tabTargets.find((tab) => tab.classList.contains('is-active'))
    this.show(active?.dataset.tabsIdParam || this.tabTargets[0]?.dataset.tabsIdParam)
  }

  select(event) {
    event.preventDefault()
    this.show(event.params.id)
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  show(id) {
    if (!id) return

    this.tabTargets.forEach((tab) => {
      const on = tab.dataset.tabsIdParam === id
      tab.classList.toggle('is-active', on)
      tab.setAttribute('aria-selected', on ? 'true' : 'false')
    })

    this.panelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.panelId !== id
    })
  }
}
