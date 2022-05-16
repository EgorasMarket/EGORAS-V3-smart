import React from 'react'
import {Navbar,NavbarBrand,NavbarToggler,Collapse,Nav,NavItem,NavLink,UncontrolledDropdown,DropdownToggle,NavbarText,DropdownMenu,DropdownItem } from 'reactstrap';
import {Authenticate} from "../../auth/Authenticate";
const Header = () => {
  return (
    <div>
    <Navbar
      color="light"
      expand="md"
      light
    >
      <NavbarBrand href="/">
        Egoras Loan Diamond
      </NavbarBrand>
      <NavbarToggler onClick={function noRefCheck(){}} />
      <Collapse navbar>
        <Nav
          className="me-auto"
          navbar
        >
      
            {/* <NavLink href="https://github.com/reactstrap/reactstrap">
              GitHub
            </NavLink>
          </NavItem> */}
          {/* <UncontrolledDropdown
            inNavbar
            nav
          >
            <DropdownToggle
              caret
              nav
            >
              Options
            </DropdownToggle>
            <DropdownMenu right>
              <DropdownItem>
                Option 1
              </DropdownItem>
              <DropdownItem>
                Option 2
              </DropdownItem>
              <DropdownItem divider />
              <DropdownItem>
                Reset
              </DropdownItem>
            </DropdownMenu>
          </UncontrolledDropdown> */}
        </Nav>
        <NavbarText>
         <Authenticate isHome="false"/>
        </NavbarText>
      </Collapse>
    </Navbar>
  </div>
  )
}

export default Header;
