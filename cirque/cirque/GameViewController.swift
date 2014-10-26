//
//  GameViewController.swift
//  cirque
//
//  Created by Ivan Milles on 26/10/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import UIKit
import GLKit

class GameViewController: GLKViewController {

    var context: EAGLContext? = nil
    var effect: GLKBaseEffect? = nil

    deinit {
        self.tearDownGL()

        if EAGLContext.currentContext() === self.context {
            EAGLContext.setCurrentContext(nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.context = EAGLContext(API: .OpenGLES2)

        if (self.context == nil) {
            println("Failed to create ES context")
        }

        let view = self.view as GLKView
        view.context = self.context
        view.drawableDepthFormat = .Format24
        
        self.setupGL()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        if self.isViewLoaded() && self.view.window == nil {

            self.tearDownGL()

            if EAGLContext.currentContext() === self.context {
                EAGLContext.setCurrentContext(nil)
            }
            self.context = nil
        }
    }

    func setupGL() {
        EAGLContext.setCurrentContext(self.context)
    }

    func tearDownGL() {
        EAGLContext.setCurrentContext(self.context)
    }

    func update() {
    }

    override func glkView(view: GLKView, drawInRect rect: CGRect) {
        glClearColor(0.65, 0.65, 0.65, 1.0)
		glClear(GLbitfield(GL_COLOR_BUFFER_BIT));
    }
}
