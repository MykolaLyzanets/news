import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['tab', 'panel']

  connect() {
    const active = this.tabTargets.find((tab) => tab.classList.contains('is-active'))
    this.show(active?.dataset.sectionTabsIdParam || this.tabTargets[0]?.dataset.sectionTabsIdParam)
  }

  select(event) {
    event.preventDefault()
    event.stopPropagation()
    this.show(event.params.id)
  }

  show(id) {
    if (!id) return

    this.tabTargets.forEach((tab) => {
      const on = tab.dataset.sectionTabsIdParam === id
      tab.classList.toggle('is-active', on)
      tab.setAttribute('aria-selected', on ? 'true' : 'false')
    })

    this.panelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.panelId !== id
    })
  }
}
