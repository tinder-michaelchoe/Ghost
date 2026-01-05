//
//  TaskManagerExampleView.swift
//  CladsExamples
//
//  Example demonstrating a dynamic task manager with add, toggle, and delete functionality.
//

import CLADS
import CladsModules
import SwiftUI

// MARK: - Task Model

struct TaskItem: Identifiable, Equatable {
    let id: String
    var title: String
    var completed: Bool

    init(id: String = UUID().uuidString, title: String, completed: Bool = false) {
        self.id = id
        self.title = title
        self.completed = completed
    }
}

// MARK: - Task Manager Example View

public struct TaskManagerExampleView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tasks: [TaskItem] = []
    @State private var newTaskTitle: String = ""

    public init() {}

    public var body: some View {
        if let document = try? Document.Definition(jsonString: buildTaskManagerJSON()) {
            CladsRendererView(
                document: document,
                customActions: [
                    "close": { [dismiss] _, _ in
                        dismiss()
                    },
                    "addTask": { [self] _, context in
                        let title = context.stateStore.get("newTaskTitle") as? String ?? ""
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

                        await MainActor.run {
                            tasks.append(TaskItem(title: title))
                            newTaskTitle = ""
                        }
                    },
                    "toggleTask": { [self] params, _ in
                        guard let taskId = params.string("taskId") else { return }
                        await MainActor.run {
                            if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                                tasks[index].completed.toggle()
                            }
                        }
                    },
                    "deleteTask": { [self] params, _ in
                        guard let taskId = params.string("taskId") else { return }
                        await MainActor.run {
                            tasks.removeAll { $0.id == taskId }
                        }
                    },
                    "confirmDelete": { [self] _, context in
                        guard let taskId = context.stateStore.get("taskIdToDelete") as? String,
                              !taskId.isEmpty else { return }
                        await MainActor.run {
                            tasks.removeAll { $0.id == taskId }
                        }
                    }
                ]
            )
        } else {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                Text("Failed to parse Task Manager JSON")
                    .foregroundStyle(.secondary)
                Button("Dismiss") { dismiss() }
            }
        }
    }

    // MARK: - JSON Builder

    private func buildTaskManagerJSON() -> String {
        let taskListChildren: String

        if tasks.isEmpty {
            // Empty state
            taskListChildren = """
            {
              "type": "vstack",
              "alignment": "center",
              "spacing": 12,
              "padding": { "vertical": 40 },
              "children": [
                { "type": "image", "image": { "system": "checklist" }, "styleId": "emptyIcon" },
                { "type": "label", "text": "No tasks yet", "styleId": "emptyTitle" },
                { "type": "label", "text": "Add a task above to get started", "styleId": "emptySubtitle" }
              ]
            }
            """
        } else {
            // Task rows
            taskListChildren = tasks.map { task in
                let checkboxIcon = task.completed ? "checkmark.circle.fill" : "circle"
                let checkboxStyle = task.completed ? "checkboxFilled" : "checkboxEmpty"
                let titleStyle = task.completed ? "taskTitleCompleted" : "taskTitle"

                return """
                {
                  "type": "hstack",
                  "spacing": 12,
                  "alignment": { "vertical": "center" },
                  "styleId": "taskRow",
                  "children": [
                    {
                      "type": "image",
                      "image": { "system": "\(checkboxIcon)" },
                      "styleId": "\(checkboxStyle)",
                      "actions": { "onTap": { "type": "toggleTask", "taskId": "\(task.id)" } }
                    },
                    {
                      "type": "vstack",
                      "spacing": 4,
                      "alignment": "leading",
                      "children": [
                        { "type": "label", "text": "\(escapeJSON(task.title))", "styleId": "\(titleStyle)" }
                      ]
                    },
                    { "type": "spacer" },
                    {
                      "type": "image",
                      "image": { "system": "trash" },
                      "styleId": "deleteButton",
                      "actions": {
                        "onTap": {
                          "type": "sequence",
                          "steps": [
                            { "type": "setState", "path": "taskIdToDelete", "value": "\(task.id)" },
                            {
                              "type": "showAlert",
                              "title": "Delete Task",
                              "message": "Are you sure you want to delete this task?",
                              "buttons": [
                                { "label": "Cancel", "style": "cancel" },
                                { "label": "Delete", "style": "destructive", "action": "confirmDelete" }
                              ]
                            }
                          ]
                        }
                      }
                    }
                  ]
                }
                """
            }.joined(separator: ",\n")
        }

        return """
        {
          "id": "task-manager",
          "version": "1.0",
          "state": {
            "newTaskTitle": "\(escapeJSON(newTaskTitle))",
            "taskIdToDelete": ""
          },
          "styles": {
            "screenTitle": { "fontSize": 32, "fontWeight": "bold", "textColor": "#000000" },
            "subtitle": { "fontSize": 14, "textColor": "#8E8E93" },
            "sectionHeader": { "fontSize": 18, "fontWeight": "semibold", "textColor": "#000000" },
            "inputField": {
              "fontSize": 16, "textColor": "#000000",
              "backgroundColor": "#F2F2F7", "cornerRadius": 12,
              "padding": { "horizontal": 16, "vertical": 14 }
            },
            "addButton": {
              "fontSize": 16, "fontWeight": "semibold",
              "backgroundColor": "#007AFF", "textColor": "#FFFFFF",
              "cornerRadius": 12, "height": 48, "padding": { "horizontal": 20 }
            },
            "taskRow": { "padding": { "vertical": 12 } },
            "taskTitle": { "fontSize": 16, "textColor": "#000000" },
            "taskTitleCompleted": { "fontSize": 16, "textColor": "#8E8E93", "strikethrough": true },
            "checkboxEmpty": { "width": 24, "height": 24, "tintColor": "#C7C7CC" },
            "checkboxFilled": { "width": 24, "height": 24, "tintColor": "#34C759" },
            "deleteButton": { "width": 20, "height": 20, "tintColor": "#FF3B30" },
            "closeButton": { "width": 28, "height": 28, "tintColor": "#8E8E93" },
            "emptyIcon": { "width": 48, "height": 48, "tintColor": "#C7C7CC" },
            "emptyTitle": { "fontSize": 18, "fontWeight": "semibold", "textColor": "#8E8E93" },
            "emptySubtitle": { "fontSize": 14, "textColor": "#C7C7CC" }
          },
          "actions": {
            "close": { "type": "close" },
            "addTask": { "type": "addTask" },
            "confirmDelete": { "type": "confirmDelete" }
          },
          "root": {
            "backgroundColor": "#FFFFFF",
            "edgeInsets": { "top": 20 },
            "children": [{
              "type": "sectionLayout",
              "sectionSpacing": 24,
              "sections": [
                {
                  "id": "header",
                  "layout": { "type": "list", "showsDividers": false, "contentInsets": { "horizontal": 20 } },
                  "children": [
                    {
                      "type": "hstack",
                      "children": [
                        {
                          "type": "vstack", "alignment": "leading", "spacing": 4,
                          "children": [
                            { "type": "label", "text": "Tasks", "styleId": "screenTitle" },
                            { "type": "label", "text": "\(tasks.count) task\(tasks.count == 1 ? "" : "s")", "styleId": "subtitle" }
                          ]
                        },
                        { "type": "spacer" },
                        {
                          "type": "button",
                          "actions": { "onTap": "close" },
                          "children": [{ "type": "image", "image": { "system": "xmark.circle.fill" }, "styleId": "closeButton" }]
                        }
                      ]
                    }
                  ]
                },
                {
                  "id": "add-task",
                  "layout": { "type": "list", "showsDividers": false, "contentInsets": { "horizontal": 20 } },
                  "header": { "type": "label", "text": "Add New Task", "styleId": "sectionHeader", "padding": { "bottom": 12 } },
                  "children": [
                    {
                      "type": "hstack", "spacing": 12,
                      "children": [
                        { "type": "textfield", "placeholder": "What needs to be done?", "styleId": "inputField", "bind": "newTaskTitle" },
                        { "type": "button", "text": "Add", "styleId": "addButton", "actions": { "onTap": "addTask" } }
                      ]
                    }
                  ]
                },
                {
                  "id": "task-list",
                  "layout": { "type": "list", "showsDividers": \(tasks.isEmpty ? "false" : "true"), "contentInsets": { "horizontal": 20 } },
                  "header": { "type": "label", "text": "Your Tasks", "styleId": "sectionHeader", "padding": { "bottom": 8 } },
                  "children": [
                    \(taskListChildren)
                  ]
                }
              ]
            }]
          }
        }
        """
    }
}

private func escapeJSON(_ string: String) -> String {
    string
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
        .replacingOccurrences(of: "\r", with: "\\r")
        .replacingOccurrences(of: "\t", with: "\\t")
}

// MARK: - Sample JSON for viewing

let taskManagerJSON = """
{
  "id": "task-manager",
  "version": "1.0",
  "state": {
    "newTaskTitle": ""
  },
  "styles": {
    "screenTitle": { "fontSize": 32, "fontWeight": "bold", "textColor": "#000000" },
    "subtitle": { "fontSize": 14, "textColor": "#8E8E93" },
    "sectionHeader": { "fontSize": 18, "fontWeight": "semibold", "textColor": "#000000" },
    "inputField": {
      "fontSize": 16, "textColor": "#000000",
      "backgroundColor": "#F2F2F7", "cornerRadius": 12
    },
    "addButton": {
      "fontSize": 16, "fontWeight": "semibold",
      "backgroundColor": "#007AFF", "textColor": "#FFFFFF",
      "cornerRadius": 12, "height": 48
    },
    "taskRow": { "padding": { "vertical": 12 } },
    "taskTitle": { "fontSize": 16, "textColor": "#000000" },
    "taskTitleCompleted": { "fontSize": 16, "textColor": "#8E8E93", "strikethrough": true },
    "checkboxEmpty": { "width": 24, "height": 24, "tintColor": "#C7C7CC" },
    "checkboxFilled": { "width": 24, "height": 24, "tintColor": "#34C759" },
    "deleteButton": { "width": 20, "height": 20, "tintColor": "#FF3B30" },
    "closeButton": { "width": 28, "height": 28, "tintColor": "#8E8E93" },
    "emptyIcon": { "width": 48, "height": 48, "tintColor": "#C7C7CC" },
    "emptyTitle": { "fontSize": 18, "fontWeight": "semibold", "textColor": "#8E8E93" },
    "emptySubtitle": { "fontSize": 14, "textColor": "#C7C7CC" }
  },
  "actions": {
    "close": { "type": "dismiss" },
    "addTask": { "type": "addTask" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 20 },
    "children": [{
      "type": "sectionLayout",
      "sectionSpacing": 24,
      "sections": [
        {
          "id": "header",
          "layout": { "type": "list", "showsDividers": false, "contentInsets": { "horizontal": 20 } },
          "children": [
            {
              "type": "hstack",
              "children": [
                {
                  "type": "vstack", "alignment": "leading", "spacing": 4,
                  "children": [
                    { "type": "label", "text": "Tasks", "styleId": "screenTitle" },
                    { "type": "label", "text": "0 tasks", "styleId": "subtitle" }
                  ]
                },
                { "type": "spacer" },
                {
                  "type": "button",
                  "actions": { "onTap": "close" },
                  "children": [{ "type": "image", "image": { "system": "xmark.circle.fill" }, "styleId": "closeButton" }]
                }
              ]
            }
          ]
        },
        {
          "id": "add-task",
          "layout": { "type": "list", "showsDividers": false, "contentInsets": { "horizontal": 20 } },
          "header": { "type": "label", "text": "Add New Task", "styleId": "sectionHeader", "padding": { "bottom": 12 } },
          "children": [
            {
              "type": "hstack", "spacing": 12,
              "children": [
                { "type": "textfield", "placeholder": "What needs to be done?", "styleId": "inputField", "bind": "newTaskTitle" },
                { "type": "button", "text": "Add", "styleId": "addButton", "actions": { "onTap": "addTask" } }
              ]
            }
          ]
        },
        {
          "id": "task-list",
          "layout": { "type": "list", "showsDividers": false, "contentInsets": { "horizontal": 20 } },
          "header": { "type": "label", "text": "Your Tasks", "styleId": "sectionHeader", "padding": { "bottom": 8 } },
          "children": [
            {
              "type": "vstack",
              "alignment": "center",
              "spacing": 12,
              "padding": { "vertical": 40 },
              "children": [
                { "type": "image", "image": { "system": "checklist" }, "styleId": "emptyIcon" },
                { "type": "label", "text": "No tasks yet", "styleId": "emptyTitle" },
                { "type": "label", "text": "Add a task above to get started", "styleId": "emptySubtitle" }
              ]
            }
          ]
        }
      ]
    }]
  }
}
"""

// MARK: - Preview

#Preview {
    TaskManagerExampleView()
}
