using Microsoft.Xna.Framework.Input;
using System;
using System.Text;

namespace Boat
{
    public class InputHandler
    {
        private StringBuilder _inputText;
        private bool _isInputActive;
        private Keys[] _previousKeys;

        public InputHandler()
        {
            _inputText = new StringBuilder();
            _isInputActive = true;
            _previousKeys = new Keys[0];
        }

        public bool IsInputActive => _isInputActive;
        public string InputText => _inputText.ToString();

        public bool HandleInput()
        {
            bool inputConfirmed = false;
            var keyboardState = Keyboard.GetState();
            var keys = keyboardState.GetPressedKeys();

            foreach (var key in keys)
            {
                if (Array.IndexOf(_previousKeys, key) == -1)
                {
                    if (key == Keys.Enter)
                    {
                        if (_inputText.Length > 0)
                        {
                            _isInputActive = false;
                            inputConfirmed = true;
                        }
                    }
                    else if (key == Keys.Back && _inputText.Length > 0)
                    {
                        _inputText.Remove(_inputText.Length - 1, 1);
                    }
                    else if (key >= Keys.A && key <= Keys.Z)
                    {
                        _inputText.Append(key.ToString().ToLower());
                    }
                    else if (key >= Keys.D0 && key <= Keys.D9)
                    {
                        _inputText.Append((key - Keys.D0).ToString());
                    }
                }
            }

            _previousKeys = keys;
            return inputConfirmed;
        }

        public void Reset()
        {
            _inputText.Clear();
            _isInputActive = true;
        }
    }
}