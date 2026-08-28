--[[
    Parallax Framework
    Copyright (c) 2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.name = "Restrain"
MODULE.description = "Zip-tie restraint system that lets players tie up, search, and release others."
MODULE.author = "Riggs"

MODULE.runtime = ( istable(ax.restrain) and ax.restrain.runtime ) or {}
MODULE.sessions = ( istable(ax.restrain) and ax.restrain.sessions ) or {}

-- /me messages sent when the tie action begins. %s = target name.
MODULE.tieStartMessages = {
    "begins looping a zip-tie around %s's wrists.",
    "forces %s's hands together and readies a zip-tie.",
    "grabs %s's arms and starts binding them.",
    "moves behind %s and begins tying them up.",
    "pulls a zip-tie taut and starts restraining %s.",
    "starts securing %s's wrists behind their back.",
}

-- /me messages sent on successful tie. %s = target name.
MODULE.tieMessages = {
    "cinches the zip-tie tight around %s's wrists.",
    "finishes binding %s's hands behind their back.",
    "locks the zip-tie in place, restraining %s.",
    "pulls the strap tight, leaving %s tied up.",
    "secures %s's wrists with a sharp zip.",
    "snaps the restraint shut around %s's wrists.",
}

-- /me messages sent when an untie or cut action begins. %s = target name.
MODULE.untieStartMessages = {
    "begins picking at the restraint around %s's wrists.",
    "begins working %s's restraints loose.",
    "starts freeing %s from their bindings.",
    "starts working at the zip-tie binding %s.",
    "takes hold of %s's restraints and starts loosening them.",
}

-- /me messages sent on successful untie. %s = target name.
MODULE.untieMessages = {
    "frees %s from their restraints.",
    "pulls the broken restraint away, freeing %s.",
    "removes the zip-tie from %s's wrists.",
    "slips the restraint off %s's wrists.",
    "works the binding loose and releases %s.",
}

-- /me messages sent when the search action begins. %s = target name.
MODULE.searchStartMessages = {
    "begins patting down %s.",
    "begins rifling through %s's pockets.",
    "starts checking %s for contraband.",
    "starts searching through %s's belongings.",
    "steps up to %s and starts frisking them.",
}

-- /me messages sent on successful search completion. %s = target name.
MODULE.searchMessages = {
    "finishes patting down %s and checks their belongings.",
    "finishes rummaging through %s's belongings.",
    "gains access to %s's belongings after a thorough search.",
    "goes through %s's possessions piece by piece.",
    "turns out %s's pockets and inspects the contents.",
}

ax.restrain = MODULE
