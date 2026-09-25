import { Controller } from "@hotwired/stimulus"
import "trix"

export default class extends Controller {
  connect() {
    this.element.querySelectorAll("trix-editor").forEach((editor) => {
      editor.addEventListener("trix-file-accept", (event) => event.preventDefault())
    })
  }
}
