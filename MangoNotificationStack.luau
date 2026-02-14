--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoNotification = require(script.Parent.MangoNotification)
local MangoProtection = require(script.Parent.MangoProtection)
local resolve = Themes.resolve

local module = {}

function module.new(config: Types.MangoNotificationStackConfig): Types.MangoNotificationStack
	local theme = config.Theme

	local maxVisible = resolve(config.MaxVisible, theme and theme.NotificationMaxVisible, 3) :: number
	local stackGap = resolve(config.StackGap, theme and theme.NotificationStackGap, 8) :: number

	-- State
	local isDestroyed = false
	local activeNotifications: {Types.MangoNotification} = {}

	-- Determine parent container
	local screenGui: ScreenGui? = nil
	local parentInstance: Instance
	if config.Parent then
		parentInstance = config.Parent
	else
		local gui = MangoProtection.createScreenGui({
			DisplayOrder = 100,
		})
		screenGui = gui
		parentInstance = gui
	end

	-- Compute Y position for a notification at the given index (1-based)
	local function computeYForIndex(index: number): number
		local y = 16
		for i = 1, index - 1 do
			local notif = activeNotifications[i]
			if notif then
				y = y + notif:GetHeight() + stackGap
			end
		end
		return y
	end

	-- Reflow all active notifications to fill gaps
	local function reflowNotifications()
		for i, notif in activeNotifications do
			local y = computeYForIndex(i)
			notif:SetPosition(UDim2.new(0.5, 0, 0, y))
		end
	end

	-- Remove a notification from the active array and reflow
	local function removeFromArray(notification: Types.MangoNotification)
		local idx: number? = nil
		for i, notif in activeNotifications do
			if notif == notification then
				idx = i
				break
			end
		end
		if idx then
			table.remove(activeNotifications, idx)
			reflowNotifications()
		end
	end

	local self: Types.MangoNotificationStack = {
		Push = function(self: Types.MangoNotificationStack, notifConfig: Types.MangoNotificationConfig): Types.MangoNotification
			if isDestroyed then
				-- Return a dummy; won't happen in practice
				error("Cannot push to a destroyed MangoNotificationStack")
			end

			-- Auto-dismiss oldest if at max capacity
			if #activeNotifications >= maxVisible then
				local oldest = activeNotifications[1]
				if oldest then
					oldest:Dismiss()
				end
			end

			-- Wrap the OnDismissed callback to also clean up the stack
			local originalOnDismissed = notifConfig.OnDismissed

			-- Create a modified config with overridden Parent and OnDismissed
			local stackNotifConfig: Types.MangoNotificationConfig = {
				Title = notifConfig.Title,
				Body = notifConfig.Body,
				Icon = notifConfig.Icon,
				Duration = notifConfig.Duration,
				Theme = notifConfig.Theme or theme,
				Parent = parentInstance,
				OnDismissed = nil, -- set below
			}

			-- We need a forward reference to the notification for the dismiss callback
			local notificationRef: Types.MangoNotification? = nil

			stackNotifConfig.OnDismissed = function()
				if notificationRef then
					removeFromArray(notificationRef :: Types.MangoNotification)
				end
				if originalOnDismissed then
					originalOnDismissed()
				end
			end

			local notification = MangoNotification.new(stackNotifConfig)
			notificationRef = notification

			-- Position the new notification
			table.insert(activeNotifications, notification)
			local y = computeYForIndex(#activeNotifications)
			notification.Container.Position = UDim2.new(0.5, 0, 0, -80) -- start offscreen
			notification:Show()
			notification:SetPosition(UDim2.new(0.5, 0, 0, y))

			return notification
		end,
		DismissAll = function(self: Types.MangoNotificationStack)
			-- Copy array since Dismiss triggers removal
			local copy = table.clone(activeNotifications)
			for _, notif in copy do
				notif:Dismiss()
			end
		end,
		GetCount = function(self: Types.MangoNotificationStack): number
			return #activeNotifications
		end,
		Destroy = function(self: Types.MangoNotificationStack)
			if isDestroyed then
				return
			end
			isDestroyed = true

			-- Dismiss all active notifications
			local copy = table.clone(activeNotifications)
			for _, notif in copy do
				notif:Destroy()
			end
			table.clear(activeNotifications)

			if screenGui then
				screenGui:Destroy()
			end
		end,
	}

	return self
end

return module
